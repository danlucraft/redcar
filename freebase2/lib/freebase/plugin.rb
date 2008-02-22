# Purpose: Wrapper for FreeBASE plugin instanciation
#    
# $Id: plugin.rb,v 1.2 2003/06/11 21:23:01 ljulliar Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
# 
# Copyright (c) 2001 Rich Kilmer. All rights reserved.
#

require 'rexml/document'

module FreeBASE

  module StandardPlugin
      def load(plugin)
        plugin.transition(FreeBASE::LOADED)
      end
      
      def start(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def stop(plugin)
        plugin.transition(FreeBASE::LOADED)
      end
      
      def unload(plugin)
        plugin.transition(FreeBASE::UNLOADED)
      end
  end
  
  class SubsystemPlugin
    extend StandardPlugin
  end

  ##
  # The Plugin class is the wrapper for the actual plugin instance
  #
  class Plugin
    
    attr_reader :plugin_configuration, :core
    
    #transition definitions
    FAILURE_TRANSITIONS = 
      { LOADING   => UNLOADED, 
        STARTING  => LOADED, 
        STOPPING  => RUNNING, 
        UNLOADING => LOADED }
                            
    LEGAL_TRANSITIONS = 
      { UNLOADED  => [LOADING],
        LOADING   => [LOADED],
        LOADED    => [STARTING, UNLOADING],
        STARTING  => [RUNNING],
        RUNNING   => [STOPPING],
        STOPPING  => [LOADED, RUNNING],
        UNLOADING => [UNLOADED] }
                    
    SYSTEM_TRANSITIONS = 
      { LOADING   => [UNLOADED, :load],
        STARTING  => [LOADED, :start],
        STOPPING  => [RUNNING, :stop],
        UNLOADING => [LOADED, :unload] }
        
    ST_CONDITION = 0
    ST_METHOD = 1
                           
    ##
    # Returns the properties object for this plugin.  This raises an
    # exception if there is not properties file definded in the plugin.xml
    # file <properties>.....</properties.
    #
    # return:: [FreeBASE::DataBus::Properties] The Properties object
    # raise:: [RuntimException] If the properties is undefined.
    #
    def properties
      raise "No properties file defined for #{@plugin_configuration.name} in plugin.xml" unless @properties
      @properties
    end
    
    ##
    # Loads the supplied .xml file and extracts its attribute values
    #
    # core:: [FreeBASE::Core] The FreeBASE core instance
    # plugin_configuration:: [FreeBASE::PluginConfiguration] The object that holds this plugin's configuration
    #
    def initialize(core, plugin_configuration)
      @core = core
      @plugin_configuration = plugin_configuration
      # configure base slot
      @base_slot = @core.bus["/plugins/#{@plugin_configuration.name}"]
      @base_slot.propagate_notifications = false
      @base_slot.manager = self
      # create properties manager
      if @plugin_configuration.properties_path
        @properties = Properties.new(@plugin_configuration.name, "1.0", @base_slot["properties"], @plugin_configuration.base_path+"/"+@plugin_configuration.properties_path) 
      end
      #local log
      @base_slot["log/info"].queue
      @base_slot["log/error"].queue
      @base_slot["log/debug"].queue
      @base_slot["log"].subscribe self
      @base_slot["state"].data = UNLOADED
      @base_slot["info/author"].data = @plugin_configuration.author
      @base_slot["info/version"].data = @plugin_configuration.version
      @base_slot["info/description"].data = @plugin_configuration.description
      @base_slot["actions/reload"].set_proc do 
        self.reload
      end
      if @plugin_configuration.test_path
        @base_slot["actions/test"].set_proc do 
          self.test
        end
      end
    end
    
    ##
    # Gets the info log slot
    #
    # return:: [FreeBASE::DataBus::Slot] The slot used for logging informational messages
    #
    def log_info
      @base_slot["log/info"]
    end
    
    ##
    # Gets the debug log slot
    #
    # return:: [FreeBASE::DataBus::Slot] The slot used for logging debug messages
    #
    def log_debug
      @base_slot["log/debug"]
    end
    
    ##
    # Gets the error log slot
    #
    # return:: [FreeBASE::DataBus::Slot] The slot used for logging error messages
    #
    def log_error
      @base_slot["log/error"]
    end
    
    ##
    # Handle callback from Slot object
    #
    def databus_notify(event, slot)
      basePath = @base_slot.path
      case slot.path
      when basePath+"log/info/", basePath+"log/error/", basePath+"log/debug/"
        if event == :notify_queue_join
          @base_slot["/log/#{slot.name}"].queue << "Plugin(#{@plugin_configuration.name}): #{slot.queue.leave}" 
        end
      end
    end
    
    ##
    # Transitions from current state to error state
    # as specified in FAILURE_TRANSITIONS table
    #
    def transition_failure
      state = FAILURE_TRANSITIONS[@base_slot["state"].data]
      @base_slot["state"].data = state if state
    end
    
    ##
    # Transitions to the new state (sets ./state slot)
    #
    # state:: [String] The state to transition to
    # raise:: [RuntimeException] If you cannot transition from current to proposed state
    #
    def transition(state)
      currentState = @base_slot["state"].data
      @base_slot["log/debug"] << "State transition: #{currentState} -> #{state}"
#       puts "#{plugin_configuration.name} State transition: #{currentState} -> #{state}"
#       puts "dependencies: #{plugin_configuration.fwd_start_graph.map{|p| p.name}.inspect}"
#       puts "reverse_deps: #{plugin_configuration.rev_start_graph.map{|p| p.name}.inspect}"
      unless LEGAL_TRANSITIONS[currentState].include?(state)
        raise "Cannot transition to #{state} from #{currentState}"
      end
      @base_slot["state"].data = state
    end
    
    def state
      @base_slot['state'].data
    end
    
    ##
    # Loads the plugin instance by calling load on the Module defined by startup_module.
    #
    def load
      transition(LOADING)
      begin
        raise Exception.new("unment dependencies") unless @plugin_configuration.dependencies_met?
        log_requires do
          require @plugin_configuration.require_path if @plugin_configuration.require_path
          eval(@plugin_configuration.startup_module).load(self)
        end
      rescue Exception => error
        puts error
        puts error.backtrace
        log_error << "Error loading #{@plugin_configuration.name}\n#{error.to_s}\n#{error.backtrace.join("\n")}"
        transition_failure
      end
    end
    
    ##
    # Starts the plugin instance by calling start on the Module defined by startup_module.
    #
    def start
      if @base_slot['state'].data == LOADED
        transition(STARTING)
        begin
          raise Exception.new("unment dependencies") unless @plugin_configuration.dependencies_met?
          log_requires do
            eval(@plugin_configuration.startup_module).start(self)
          end
        rescue Exception => error
          puts error
          puts error.backtrace
          log_error << "Error starting #{@plugin_configuration.name}\n#{error.to_s}\n#{error.backtrace.join("\n")}"
          transition_failure
        end
      end
    end
    
    ##
    # Stops the plugin instance by calling stop on the Module defined by startup_module.
    #
    def stop
      if @base_slot["state"].data == RUNNING
        transition(STOPPING) 
        eval(@plugin_configuration.startup_module).stop(self)
      end
    end
    
    ##
    # Unloads the plugin instance by calling unload on the Module defined by startup_module.
    #
    def unload
      if @base_slot['state'].data == LOADED
        transition(UNLOADING)
        eval(@plugin_configuration.startup_module).unload(self)
      end
    end
    
    ##
    # Calls the [](path) method on the @local_bus DataBus
    #
    def [](path)
      return @base_slot[path]
    end
    
    ##
    # Logs all files that Ruby loads during the invocation of the block passed in.
    #
    def log_requires(type=:plugin)
      before = $".dup
      yield
      after = $".dup
      prev = @base_slot["files/"+type.to_s].data || []
      @base_slot["files/"+type.to_s].data = (prev + (after-before)).uniq
    end
    
    ##
    # Reloads all files logged as having been loaded by this plugin.
    #
    def reload
      puts "reloading #{@plugin_configuration.name}"
      
      # remove methods from testcase
      if pm = @plugin_configuration.test_module
        begin
          if tc = eval(pm)
            tc.instance_methods.select{|m| m=~/^test_/}.each do |meth|
              tc.class_eval { remove_method(meth) }
            end
          end
        rescue
        end
      end
        
      @base_slot["files"].each_slot do |s|
        (s.data||[]).each do |f|
          if File.extname(f) == ".rb"
            Kernel.load f
          end
        end
      end
    end
    
    ##
    # Loads and executes the plugin's test path.
    #
    def test(output=:console)
      if @plugin_configuration.test_path
        require 'test/unit'
        
        # we do not want the tests to run on exit:
        Test::Unit.run = false
        
        log_requires(:test) do
          require @plugin_configuration.test_path
        end
        
        case output
        when :console
          require 'test/unit/ui/console/testrunner'
          begin
            Test::Unit::UI::Console::TestRunner.new(eval(@plugin_configuration.test_module).suite).start
          rescue Object => e
            puts e
            puts e.message
            puts e.backtrace
          end
        end
      end
    end
  end
end
