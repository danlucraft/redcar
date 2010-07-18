
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
  	end
  	
  	def install
  	  unless File.writable?(JRUBY_JAR_DIR)
  	    puts "Don't have permission to write to #{JRUBY_JAR_DIR}. Please rerun with sudo."
  	    exit 1
  	  end
      Redcar.environment = :user
  	  puts "Downloading >10MB of jar files. This may take a while."
  	  grab_jruby
  	  grab_common_jars
  	  grab_platform_dependencies
  	  grab_redcar_jars
      puts "Building textmate bundle cache"
      s = Time.now
      load_textmate_bundles
      puts "... took #{Time.now - s}s"
      fix_user_dir_permissions
  	  puts
  	  puts "Done! You're ready to run Redcar."
  	end
  
    def associate_with_any_right_click
      raise 'this is currently only for windows' unless Redcar.platform == :windows  	  
      require 'rbconfig'
      require 'win32/registry'
      # associate it with the current rubyw.exe
      rubyw_bin = File.join([Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name']]) << 'w' << Config::CONFIG['EXEEXT']
      if rubyw_bin.include? 'file'
        raise 'this must be run from a ruby exe, not a java -cpjruby.jar command'
      end
      rubyw_bin.gsub!('/', '\\') # executable names wants back slashes
      for type, english_text  in {'*' => 'Open with Redcar', 'Directory' => 'Open with Redcar (dir)'}
        name = Win32::Registry::HKEY_LOCAL_MACHINE.create "Software\\classes\\#{type}\\shell\\open_with_redcar"
        name.write_s nil, english_text
        dir = Win32::Registry::HKEY_LOCAL_MACHINE.create "Software\\classes\\#{type}\\shell\\open_with_redcar\\command"
        command = %!"#{rubyw_bin}" "#{File.expand_path($0)}" "%1"!
        dir.write_s nil, command
      end
      puts 'Associated.'
    end

    def plugins_dir
      File.expand_path(File.join(File.dirname(__FILE__), %w(.. .. plugins)))
    end
    
    ASSET_HOST = "http://redcar.s3.amazonaws.com"
    
    JFACE = %w(
      /jface/org.eclipse.core.commands.jar
      /jface/org.eclipse.core.runtime_3.5.0.v20090525.jar
      /jface/org.eclipse.equinox.common.jar
      /jface/org.eclipse.jface.databinding_1.3.0.I20090525-2000.jar
      /jface/org.eclipse.jface.jar
      /jface/org.eclipse.jface.text_3.5.0.jar
      /jface/org.eclipse.osgi.jar
      /jface/org.eclipse.text_3.5.0.v20090513-2000.jar
      /jface/org.eclipse.core.resources.jar
      /jface/org.eclipse.core.jobs.jar
    )
    
    def redcar_jars_dir
      File.expand_path(File.join(Redcar.user_dir, "jars"))
    end
    
    JRUBY_JAR_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    
    JRUBY = [
      "/jruby/jcodings.jar",
      "/jruby/jdom.jar",
      "/jruby/joni.jar"
    ]

    JRUBY << "http://jruby.org.s3.amazonaws.com/downloads/1.5.0/jruby-complete-1.5.0.jar"
    
    JOPENSSL_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", "openssl/lib/")) 
    JOPENSSL = {
      "/jruby/bcmail-jdk14-139-#{Redcar::VERSION}.jar" => "bcmail-jdk14-139.jar",
      "/jruby/bcprov-jdk14-139-#{Redcar::VERSION}.jar" => "bcprov-jdk14-139.jar",
      "/jruby/jopenssl-#{Redcar::VERSION}.jar"         => "jopenssl.jar",
    }

    REDCAR_JARS = {
      "/java-mateview-#{Redcar::VERSION}.jar" => "plugins/edit_view_swt/vendor/java-mateview.jar",
      "/application_swt-#{Redcar::VERSION}.jar" => "plugins/application_swt/lib/dist/application_swt.jar",
      "/clojure.jar" => "plugins/repl/vendor/clojure.jar"
    }
    
    XULRUNNER_URI = "http://releases.mozilla.org/pub/mozilla.org/xulrunner/releases/1.9.2.6/runtimes/xulrunner-1.9.2.6.en-US.win32.zip"

    SWT_JARS = {
      :osx     => {
        "/swt/osx.jar"     => "osx/swt.jar",
        "/swt/osx64.jar"   => "osx64/swt.jar"
      },
      :linux   => {
        "/swt/linux.jar"   => "linux/swt.jar",
        "/swt/linux64.jar" => "linux64/swt.jar"
      },
      :windows => {
        "/swt/win32.jar"   => "win32/swt.jar",
      }
    }
    
    def grab_jruby
      puts "* Checking JRuby dependencies"
      
      setup "jruby",    :resources => JRUBY,    :path => JRUBY_JAR_DIR
      setup "jopenssl", :resources => JOPENSSL, :path => JOPENSSL_DIR
    end
    
    def grab_common_jars
      puts "* Checking common jars"
      
      setup "jface", :resources => JFACE, :path => File.join(plugins_dir, %w(application_swt vendor jface))
    end
    
    def grab_platform_dependencies
      puts "* Checking platform-specific SWT jars"
      case Config::CONFIG["host_os"]
      when /darwin/i
        setup "swt", :resources => SWT_JARS[:osx],     :path => File.join(plugins_dir, %w(application_swt vendor swt))

      when /linux/i
        setup "swt", :resources => SWT_JARS[:linux],   :path => File.join(plugins_dir, %w(application_swt vendor swt))

      when /windows|mswin|mingw/i
        setup "swt", :resources => SWT_JARS[:windows], :path => File.join(plugins_dir, %w(application_swt vendor swt))
        setup "swt", :resources => [XULRUNNER_URI],    :path => File.expand_path(File.join(File.dirname(__FILE__), %w(.. .. vendor)))
        link( File.join(redcar_jars_dir, "swt", "xulrunner"),
              File.expand_path(File.join(File.dirname(__FILE__), %w(.. .. vendor xulrunner))))
      end
    end
    
    def grab_redcar_jars
      puts "* Checking Redcar jars"
      setup "redcar", :resources => REDCAR_JARS, :path => File.join(File.dirname(__FILE__), "..", "..")
    end
    
    def download(uri, path)
      if uri =~ /^\//
        uri = ASSET_HOST + uri
      end
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "wb") do |write_out|
        write_out.print @connection.get(URI.parse(uri))
      end
      
      if path =~ /.*\.zip$/
      	puts '  unzipping  ' + path
      	Installer.unzip_file(path)
      end

      # puts "  downloaded #{uri}\n          to #{path}\n"
    end
    
    def setup(name, options)
      resources = options.delete(:resources)
      path      = options.delete(:path)
      
      if resources.is_a?(Array)
        resources.each do |resource|
          setup_resource name, path, resource, File.basename(resource)
        end
      else
        resources.each_pair do |url, save_as|
          setup_resource name, path, url, save_as
        end
      end
    end
    
    def setup_resource(name, path, url, save_as)
      target = File.join(path, save_as)
      return if File.exist?(target)
      
      cached = File.join(redcar_jars_dir, name, save_as)
      unless File.exists?(cached)
        print "  downloading #{File.basename(cached)}... "
        download(url, cached)
        puts "done!"
      end

      FileUtils.mkdir_p File.dirname(target)
      link(cached, target)
    end

    def link(cached, target)
      # Windoze doesn't support FileUtils.ln_sf, so we copy the files
      if Config::CONFIG["host_os"] =~ /windows|mswin|mingw/i
        puts "  copying #{File.basename(cached)}..."
        FileUtils.cp_r cached, target
      else
        puts "  linking #{File.basename(cached)}..."
        FileUtils.ln_sf cached, target
      end
    end
    
    # unzip a .zip file into the directory it is located
    def self.unzip_file(source)
      source = File.expand_path(source)
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
    
    def load_textmate_bundles
      $:.unshift("#{File.dirname(__FILE__)}/../../plugins/core/lib")
      $:.unshift("#{File.dirname(__FILE__)}/../../plugins/textmate/lib")
      require 'core'
      Redcar.environment = :user
      Core.loaded
      require 'textmate'
      Redcar::Textmate.all_bundles
    end
    
    def fix_user_dir_permissions
      desired_uid = File.stat(Redcar.home_dir).uid
      desired_gid = File.stat(Redcar.home_dir).gid
      FileUtils.chown_R(desired_uid, desired_gid.to_s, Redcar.user_dir)
    end
  end
end


