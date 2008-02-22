# Purpose: FreeBASE Core module. Starts all plugins
#    
# $Id: core.rb,v 1.4 2004/10/14 20:54:34 ljulliar Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors:
#  - Laurent Julliard <laurent AT moldus DOT org)
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
# 
# Copyright (c) 2001 Rich Kilmer. All rights reserved.
#

require 'rbconfig'

module FreeBASE
  
  ##
  # The Core class starts the FreeBASE service that manages
  # the installed plugins.
  #
  class Core

    include Config
  
    ##
    # Starts the Core service.  This method blocks until shutdown.
    #
    def Core.startup(propertiesFile, defaultPropertiesFile)
      Thread.abort_on_exception = true
      core = Core.new(propertiesFile, defaultPropertiesFile)
      yield core if block_given?
      sleep
    end
    
    # The master bus FreeBASE::DataBus
    attr_reader :bus
    
    # The logger utility
    attr_reader :log
    
    ##
    # Constructs a new Core, loads the setup.rb, and loads the plugins
    #
    def initialize(propertiesFile, defaultPropertiesFile)
      @propertiesFile = propertiesFile
      @defaultPropertiesFile = defaultPropertiesFile
      init_bus
      load_properties
      load_setup
      # push all plugin paths into the require path. Prepend codebase
      # if it's a relative path
      @properties["config/plugin_path"].split(";").each do |path|
        path = File.join($FR_CODEBASE,path) unless File.absolute_path?(path)
        $:.push path
      end
      @bus["/log/info"] << "--- #{@properties['config/product_name']} Started on #{Time.now.to_s}"
      @bus["/system/state/all_plugins_loaded"].data = false;
      @plugin_config = Configuration.new(self, @properties["config/plugin_path"])
      @plugin_config.load_plugins
      @plugin_config.start_plugins
      @bus["/system/state/all_plugins_loaded"].data = true;
      @core_thread = Thread.current
      tui = Thread.new {
        @bus["/system/ui/messagepump"].call()
      }
      tui.join
    end
    
    ##
    # Shuts down the system by notifying each installed plugin via
    # publishing the Core instance to the local plugin bus ['/command/shutdown']
    # Shutdown stops if requested by a plugin to abort.
    #
    def shutdown
      @plugin_config.stop_plugins
      @plugin_config.unload_plugins
      @bus["/system/state/all_plugins_loaded"].data = false;
      @bus["/log/info"] << "--- Shutting down #{@properties['config/product_name']} on #{Time.now.to_s}"
      @core_thread.wakeup if @core_thread.stop?
    end
    
    private
    
    def init_bus
      @bus = DataBus.new
      # Publishing an integer to this location will shut down FreeBASE in that many seconds
      @bus["/system/shutdown"].validate_with("Specify number of seconds") do |args|
        args.size==1 and args[0].respond_to? "to_i"  # validate convertable to integer
      end
      @bus["/system/shutdown"].set_proc  do |seconds|
        Thread.new do 
          puts "Shutdown in #{seconds.to_i} seconds..."
          sleep seconds.to_i
          shutdown
        end
        true
      end
      
      # Set up logger
      @bus["log/info"].queue
      @bus["log/error"].queue
      @bus["log/debug"].queue
      @bus["log"].subscribe do |event, slot|
        if event == :notify_queue_join and slot.name != "log"
          @bus["log"].call(slot.name, slot.queue.leave) if @bus["log"].is_proc_slot?
          slot.queue.leave if slot.queue.count > 500
        end
      end
    end
    
    ##
    # Loads the setup.rb file by eval'ing the contents into this instance
    #
    def load_setup
      setupFile = @properties["config/setup_file"]
      return unless (setupFile and File.exist?(setupFile))
      file = File.new(setupFile)
      setup = file.read
      file.close
      instance_eval(setup)
    end
    
    ##
    # Builds the default properties file if it does not exist
    #
    def load_properties
      unless Properties.exist?(@propertiesFile)
        Properties.copy(@defaultPropertiesFile, @propertiesFile)
        @properties = Properties.new("Core configuration file", 
                                     "1.0", 
                                     @bus["/system/properties"], 
                                     @propertiesFile)
        @properties["version/major"] = Redcar::VERSION_MAJOR
        @properties["version/minor"] = Redcar::VERSION_MINOR
        @properties["version/release"] = Redcar::VERSION_RELEASE
      else
        @properties = Properties.new("Core configuration file", 
                                     "1.0", 
                                     @bus["/system/properties"], 
                                     @propertiesFile)
        was_version = [@properties["version/major"],@properties["version/minor"],@properties["version/release"]].join('.')
        is_version = [Redcar::VERSION_MAJOR, Redcar::VERSION_MINOR, Redcar::VERSION_RELEASE].join('.')
        
        if (is_version < was_version)
          puts "="*70
          puts "WARNING!! You are running an old version of #{$FREEBASE_APPLICATION} (#{is_version}) against #{$FREEBASE_APPLICATION} configuration files created with a newer version (#{was_version}). This may cause serious troubles including #{$FREEBASE_APPLICATION} crashes."
          puts "="*70
        else
          @properties["version/major"] = Redcar::VERSION_MAJOR
          @properties["version/minor"] = Redcar::VERSION_MINOR
          @properties["version/release"] = Redcar::VERSION_RELEASE
        end
      end
      @properties['config/codebase'] = $FR_CODEBASE
    end
  end
  
end
