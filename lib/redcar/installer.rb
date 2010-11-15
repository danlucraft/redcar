
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
      puts "Downloading >10MB of binary assets. This may take a while the first time."
      fetch_all_assets
      precache_textmate_bundles
      ensure_user_plugins_directory_exists
      puts "Done! You're ready to run Redcar."
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
          "http://jruby.org.s3.amazonaws.com/downloads/1.5.3/jruby-complete-1.5.3.jar" => "/jruby-complete-1.5.3.jar",
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.core.commands.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.core.runtime_3.5.0.v20090525.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.equinox.common.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.jface.databinding_1.3.0.I20090525-2000.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.jface.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.jface.text_3.5.0.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.osgi.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.text_3.5.0.v20090513-2000.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.core.resources.jar" => nil,
          "http://redcar.s3.amazonaws.com/jface/org.eclipse.core.jobs.jar" => nil,
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
          "http://mirrors.ibiblio.org/pub/mirrors/maven2/org/codehaus/groovy/groovy-all/1.7.4/groovy-all-1.7.4.jar" => "/groovy-all.jar",
          "http://mirrors.ibiblio.org/pub/mirrors/maven2/org/tmatesoft/svnkit/svnkit/1.3.4/svnkit-1.3.4.jar" => "/svnkit.jar"
        },
        :windows => {
          "http://releases.mozilla.org/pub/mozilla.org/xulrunner/releases/#{xulrunner_version}/runtimes/xulrunner-#{xulrunner_version}.en-US.win32.zip" => "xulrunner-#{xulrunner_version}.en-US.win32.zip",
          "http://redcar.s3.amazonaws.com/swt/win32.jar"   => nil,
        },
        :linux => {
          "http://redcar.s3.amazonaws.com/swt/linux.jar"     => nil,
          "http://redcar.s3.amazonaws.com/swt/linux64.jar"   => nil
        },
        :osx => {
          "http://redcar.s3.amazonaws.com/swt/osx.jar"     => nil,
          "http://redcar.s3.amazonaws.com/swt/osx64.jar"   => nil
        }
      }
    end
    
    def fetch_asset(source, target)
      relative_target   = target || implicit_target(source)
      absolute_target   = File.join(Redcar.asset_dir, relative_target)
      return if File.exist?(absolute_target)
      download_file_to(source, absolute_target)
      unzip_file(absolute_target) if absolute_target =~ /\.zip$/
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


