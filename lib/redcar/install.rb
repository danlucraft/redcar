
require 'rbconfig'
require 'open-uri'
require 'fileutils'

module Redcar
  # Methods used in gem installation hooks
  #
  # Cribbed from the zerg and zerg_support gems by Victor Costan (big woop!)
  class Install
    
    # tricks rubygems into believeing that the extension compiled and worked out
    def emulate_extension_install(extension_name)
      File.open('Makefile', 'w') { |f| f.write "all:\n\ninstall:\n\n" }
      File.open('make', 'w') do |f|
        f.write '#!/bin/sh'
        f.chmod f.stat.mode | 0111
      end
      File.open(extension_name + '.so', 'w') {}
      File.open(extension_name + '.dll', 'w') {}
      File.open('nmake.bat', 'w') { |f| }
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
    
    JRUBY = %w(
      /jruby/jruby-complete-1.4.0.jar
      /jruby/jcodings.jar
      /jruby/jdom.jar
      /jruby/joni.jar
    )

    REDCAR_JARS = {
      "/java-mateview.jar" => "plugins/edit_view_swt/vendor/java-mateview.jar"
    }

    def grab_jruby
      puts "* Downloading JRuby"
      JRUBY.each do |jar_url|
        download(jar_url, File.expand_path(File.join(File.dirname(__FILE__), "..", File.basename(jar_url))))
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
      when /windows|mswin/i
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
      uri = ASSET_HOST + uri
      FileUtils.mkdir_p(File.dirname(path))
      write_out = open(path, "wb")
      write_out.write(open(uri).read)
      write_out.close
      puts "  downloaded #{uri}\n          to #{path}\n"
    end
  end
end
