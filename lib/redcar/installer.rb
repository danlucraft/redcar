
require 'net/http'
require 'fileutils'

if Redcar.platform == :windows
  require "rubygems"
  require "zip/zipfilesystem"
end

module Redcar
  class Installer
    def initialize
      if ENV['http_proxy']
        proxy = URI.parse(ENV['http_proxy'])
        @connection = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password)
      else
        @connection = Net::HTTP
      end
      puts "found latest XULRunner release version: #{xulrunner_version}" if Redcar.platform == :windows
    end

    def install
      Redcar.environment = :user
      puts "Downloading >10MB of necessary assets..."
      fetch_all_assets
      precache_textmate_bundles
      ensure_user_plugins_directory_exists
      replace_windows_batch_file
      puts "Success!"
      puts ""
      puts "To open just the editor:       redcar"
      puts "To open the current directory: redcar ."
      puts "More information:              http://redcareditor.com/"
    end

    def plugins_dir
      File.expand_path(File.join(File.dirname(__FILE__), %w(.. .. plugins)))
    end

    def fetch_all_assets
      assets = assets_by_platform[:all].merge(assets_by_platform[Redcar.platform])
      assets.each {|source, target| fetch_asset(source, target) }
    end

    def assets_by_platform
      { :all => {
          "http://redcar.s3.amazonaws.com/jruby/jcodings.jar" => "/jcodings.jar",
          "http://redcar.s3.amazonaws.com/jruby/jdom.jar" => "/jdom.jar",
          "http://redcar.s3.amazonaws.com/jruby/joni.jar" => "/joni.jar",
          "http://redcar.s3.amazonaws.com/jruby/bcmail-jdk14-139-redcar1.jar" => "/bcmail-jdk14-139.jar",
          "http://redcar.s3.amazonaws.com/jruby/bcprov-jdk14-139-redcar1.jar" => "/bcprov-jdk14-139.jar",
          "http://redcar.s3.amazonaws.com/jruby/jopenssl-redcar1.jar"         => "/jopenssl.jar",
          "http://redcar.s3.amazonaws.com/java-mateview-#{Redcar::VERSION}.jar" => nil,
          "http://redcar.s3.amazonaws.com/application_swt-#{Redcar::VERSION}.jar" => nil,
          "http://redcar.s3.amazonaws.com/clojure-1.2beta1.jar" => "/clojure.jar",
          "http://redcar.s3.amazonaws.com/clojure-contrib-1.2beta1.jar" => "/clojure-contrib.jar",
          "http://redcar.s3.amazonaws.com/org-enclojure-repl-server.jar" => nil,
          "http://mirrors.ibiblio.org/pub/mirrors/maven2/org/tmatesoft/svnkit/svnkit/1.3.4/svnkit-1.3.4.jar" => "/svnkit.jar",
          # "http://mirrors.ibiblio.org/pub/mirrors/maven2/rhino/js/1.7R2/js-1.7R2.jar" => "/js.jar",
          "http://redcar.s3.amazonaws.com/deps/rhino-js-1.7R2.jar" => "/js.jar",
        },
        :windows => {
          "http://releases.mozilla.org/pub/mozilla.org/xulrunner/releases/#{xulrunner_version}/runtimes/xulrunner-#{xulrunner_version}.en-US.win32.zip" => "xulrunner-#{xulrunner_version}.en-US.win32.zip",
        },
        :linux => {
        },
        :osx => {
        }
      }
    end

    def fetch_asset(source, target)
      relative_target   = target || implicit_target(source)
      absolute_target   = File.join(Redcar.asset_dir, relative_target)
      if File.exist?(absolute_target)
        unless source =~ /dev\.jar/
          return
        end
      end
      download_file_to(source, absolute_target)
      unzip_file(absolute_target) if absolute_target =~ /\.zip$/
    end
    
    def replace_windows_batch_file
      if RUBY_PLATFORM.downcase =~ /mswin|mingw|win32/
        require 'rbconfig'
        bin_dir = Config::CONFIG["bindir"]
        ruby_path = File.join(bin_dir,
                                  "rubyw.exe")
        script_path = File.join(bin_dir,"redcar.bat")
        File.open script_path, 'w' do |file|
          file.puts <<-TEXT
@Echo Off
IF NOT "%~f0" == "~f0" GOTO :WinNT
@"#{ruby_path}" "#{File.join(bin_dir,"redcar")}" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF
:WinNT
SET STARTUP=%*
SET RUBY="rubyw.exe"

:LOOP
if "%1"=="--with-windows-console" GOTO USERUBY
if "%1"=="" GOTO STARTREDCAR
shift
GOTO LOOP

:USERUBY
SET RUBY="ruby.exe"

:STARTREDCAR
IF NOT "X"%STARTUP% == "X" SET STARTUP=%STARTUP:"="""%
start "RedCar" %RUBY% "#{File.join(bin_dir,"redcar")}" %STARTUP%
TEXT
        end
      end
    end

    def implicit_target(source)
      URI.parse(source).path.gsub(/^\//, "")
    end

    def download_file_to(uri, destination_file)
      print "  downloading #{uri}... "; $stdout.flush
      temporary_target  = destination_file + ".part"
      FileUtils.mkdir_p(File.dirname(destination_file))
      File.open(temporary_target, "wb") do |write_out|
        write_out.print @connection.get(URI.parse(uri))
      end

      if File.open(temporary_target).read(200) =~ /Access Denied/
        puts "\n\n*** Error downloading #{uri}, got Access Denied from S3."
        FileUtils.rm_rf(temporary_target)
        exit
      end

      FileUtils.cp(temporary_target, destination_file)
      FileUtils.rm_rf(temporary_target)
      puts "done!"
    end

    # unzip a .zip file into the directory it is located
    def unzip_file(path)
      print "unzipping #{path}..."; $stdout.flush
      source = File.expand_path(path)
      Dir.chdir(File.dirname(source)) do
        Zip::ZipFile.open(source) do |zipfile|
          zipfile.entries.each do |entry|
            FileUtils.mkdir_p(File.dirname(entry.name))
            begin
              entry.extract
            rescue Zip::ZipDestinationFileExistsError
            end
          end
        end
      end
    end

    def precache_textmate_bundles
      puts "Precaching textmate bundles..."
      Runner.new.construct_command(["--no-gui", "--compute-textmate-cache-and-quit", "--multiple-instance"]) do |cmd|
        %x{#{cmd.join(' ')}}
      end
    end

    def ensure_user_plugins_directory_exists
      FileUtils.mkpath File.join(Redcar.user_dir, 'plugins')
    end

    # Xulrunner releases don't hang around very long, so we scrape their site to figure out
    # which one to download this time.
    def xulrunner_version
      @xulrunner_version ||= begin
        html = @connection.get(URI.parse("http://releases.mozilla.org/pub/mozilla.org/xulrunner/releases/"))
        html.scan(/\d\.\d\.\d\.\d+/).sort.reverse.first
      end
    end
  end
end
