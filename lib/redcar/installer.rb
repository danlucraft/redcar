
require 'net/http'
require 'fileutils'

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

  	def install
  	  unless File.writable?(JRUBY_JAR_DIR)
  	    puts "Don't have permission to write to #{JRUBY_JAR_DIR}. Please rerun with sudo."
  	    exit 1
  	  end
  	  puts "Downloading >10MB of jar files. This may take a while."
  	  grab_jruby
  	  grab_common_jars
  	  grab_platform_dependencies
  	  grab_redcar_jars
  	  puts
  	  puts "Done! You're ready to run Redcar."
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
    )
    
    JRUBY_JAR_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    
    JRUBY = [
      "http://jruby.kenai.com/downloads/1.4.0/jruby-complete-1.4.0.jar",
      "/jruby/jcodings.jar",
      "/jruby/jdom.jar",
      "/jruby/joni.jar"
    ]
    
    JOPENSSL = {
      "/jruby/bcmail-jdk14-139-#{Redcar::VERSION}.jar" => "lib/openssl/lib/bcmail-jdk14-139.jar",
      "/jruby/bcprov-jdk14-139-#{Redcar::VERSION}.jar" => "lib/openssl/lib/bcprov-jdk14-139.jar",
      "/jruby/jopenssl-#{Redcar::VERSION}.jar"         => "lib/openssl/lib/jopenssl.jar",
    }

    REDCAR_JARS = {
      "/java-mateview-#{Redcar::VERSION}.jar" => "plugins/edit_view_swt/vendor/java-mateview.jar"
    }

    def grab_jruby
      puts "* Downloading JRuby"
      JRUBY.each do |jar_url|
        download(jar_url, File.join(JRUBY_JAR_DIR, File.basename(jar_url)))
      end
      JOPENSSL.each do |jar_url, relative_path|
        download(jar_url, File.join(File.dirname(__FILE__), "..", "..", relative_path))
      end
    end
    
    def grab_common_jars
      puts "* Downloading common jars"
      JFACE.each do |jar_url|
        download(jar_url, File.join(plugins_dir, %w(application_swt vendor jface), File.basename(jar_url)))
      end
    end
    
    def grab_platform_dependencies
      puts "* Downloading platform-specific SWT jars"
      case Config::CONFIG["host_os"]
      when /darwin/i
        download("/swt/osx.jar", File.join(plugins_dir, %w(application_swt vendor swt osx swt.jar)))
        download("/swt/osx64.jar", File.join(plugins_dir, %w(application_swt vendor swt osx64 swt.jar)))
      when /linux/i
        download("/swt/linux.jar", File.join(plugins_dir, %w(application_swt vendor swt linux swt.jar)))
        download("/swt/linux64.jar", File.join(plugins_dir, %w(application_swt vendor swt linux64 swt.jar)))
      when /windows|mswin|mingw/i
        download("/swt/win32.jar", File.join(plugins_dir, %w(application_swt vendor swt win32 swt.jar)))
        # download("/swt/win64.jar", File.join(plugins_dir, %w(application_swt vendor swt win64 swt.jar)))
      end
    end
    
    def grab_redcar_jars
      puts "* Downloading Redcar jars"
      REDCAR_JARS.each do |jar_url, relative_path|
        download(jar_url, File.join(File.dirname(__FILE__), "..", "..", relative_path))
      end
    end
    
    def download(uri, path)
      if uri =~ /^\//
        uri = ASSET_HOST + uri
      end
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "wb") do |write_out|
        write_out.print @connection.get(URI.parse(uri))
      end

      puts "  downloaded #{uri}\n          to #{path}\n"
    end
  end
end
