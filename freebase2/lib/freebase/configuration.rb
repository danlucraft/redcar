# Purpose: Configuration classes for FreeBASE
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

module FreeBASE

  ##
  # Main configuration control class.  Responsible for processing
  # subsystem/plugins from supplied paths, resolving dependencies,
  # and providing plugin lifecycle (load/start/stop/unload).
  #
  class Configuration
    
    attr_reader :plugins, :core, :plugin_paths
    
    ##
    # Creates a configuration class from for the given FreeBASE core.
    # Reads in the configuration files and resolves dependencies
    #
    # core:: [FreeBASE::Core] The core object.
    # plugin_paths:: [String] A semicolon separated list of directories to search for plugins
    #
    def initialize(core, plugin_paths)
      @core = core
      @plugin_paths = plugin_paths
      @plugins = {}
      YAMLConfigurationReader.new(self)
      resolve_dependencies
    end
    
    ##
    # Regsiters a config object (subsystem or plugin) with FreeBASE
    #
    # config:: [FreeBASE::SubsystemConfiguration | FreeBASE::PluginConfiguration] The configuration object
    #
    def register(config, base_path)
      config.configuration = self
      config.base_path = base_path
      if File.absolute_path?(base_path)
        config.full_base_path = base_path
      else
        config.full_base_path = File.expand_path(File.join($FR_CODEBASE, base_path))
      end
      if config.kind_of? SubsystemConfiguration
        config.each_plugin {|plugin_config| register(plugin_config, base_path)}
        return
      end
      @plugins[config.name] = config if config.autoload?
    end
    
    ##
    # Loads all the plugins based on the load list calculated by the dependency resolution
    #
    def load_plugins
      num = 0
      while num < @load_list.size
        plugin = @load_list[num]
        plugin.instance.load
        if plugin.instance.state != LOADED
          puts "[FB2] failed to load: #{plugin.name}"
          fail_load_dependencies(plugin)
          fail_start_dependencies(plugin)
        else
#          puts "[FB2] loaded: #{plugin.name}"
          num += 1
        end
      end
    end
    
    ##
    # Starts all the plugins based on the start list calculated by the dependency resolution
    #
    def start_plugins
      num = 0
      while num < @start_list.size
        plugin = @start_list[num]
        plugin.instance.start
        if plugin.instance.state != RUNNING
          puts "[FB2] failed to start: #{plugin.name}"
          fail_start_dependencies(plugin)
        else
#          puts "[FB2] started: #{plugin.name}"
          num += 1
        end
      end
    end
    
    ##
    # Stops all the plugins based on reversing the start list calculated by the dependency resolution
    #
    def stop_plugins
      @start_list.reverse.each do |plugin|
        plugin.instance.stop
      end
    end
    
    ##
    # Unloads all the plugins based on by reversing the load list calculated by the dependency resolution
    #
    def unload_plugins
      @load_list.reverse.each do |plugin|
        plugin.instance.unload
      end
    end
    
    private
    
    def fail_load_dependencies(plugin)
      puts "Failing to load: #{plugin.name}"
      @load_list.delete(plugin)
      plugin.rev_load_graph.each { |other| fail_load_dependencies(other) }
    end
    
    def fail_start_dependencies(plugin)
      puts "Failing to start: #{plugin.name}"
      @start_list.delete(plugin)
      plugin.rev_start_graph.each { |other| fail_start_dependencies(other) }
    end
    
    def resolve_dependencies
      # graph dependencies
      @plugins.each_value do |plugin|
        plugin.build_graph
      end
      # compute load and start levels
      @plugins.each_value do |plugin|
        plugin.compute_levels
      end
      # build load list
      @load_list = @plugins.values
      @load_list.sort! do |a, b|
        a.load_level<=>b.load_level
      end
      # build start list
      @start_list = @plugins.values
      @start_list.sort! do |a, b|
        a.start_level<=>b.start_level
      end
    end
    
    def debug
     @plugins.each do |name, plugin|
        puts "Plugin: #{name} Load Level:  #{plugin.load_level} Dep: #{plugin.fwd_load_graph.collect {|p| p.name}.join(', ')}"
      end
      puts "_"*30
      @load_list.each {|plugin| puts "#{plugin.load_level}: #{plugin.name}"}
      puts "_"*30
      puts "_"*30
      @plugins.each do |name, plugin|
        puts "Plugin: #{name} Start Level: #{plugin.start_level} Dep: #{plugin.fwd_start_graph.collect {|p| p.name}.join(', ')}"
      end
      puts "_"*30
      @start_list.each {|plugin| puts "#{plugin.start_level}: #{plugin.name}"}
      exit
    end
    
  end
  
  ##
  # Represents a subsystem (set of plugins) in FreeBASE.  It creates
  # a plugin named the subsystem name which is dependent on all plugins
  # in the subsystem.  This allows another plugin to be dependent on
  # all the plugins in the subsystem by simply being dependent on the
  # plugin named after the subsystem
  #
  class SubsystemConfiguration
    attr_accessor :name, :version, :base_path, :full_base_path
    attr_reader :plugins
    attr_reader :configuration
    
    ##
    # Orders the properties to export when this object is serialized
    # to YAML
    #
    # return:: [Array] List of properties to export...used by YAML
    #
    def to_yaml_properties
      ['@name', '@version', '@plugins']
    end
    
    ##
    # Constructs a SubsystemConfiguration object.  May optionally
    # supply block with yielded instance of 'self' to set properties.
    #
    def initialize
      @plugins = []
      yield self if block_given?
    end
    
    ##
    # Set the configuration instance.  Also builds the plugin which represents
    # the subsystem.  This should be called only after all plugins configurations 
    # have beed processed and added to this subsystem.
    #
    # configuration:: [FreeBASE::Configuration] The FreeBASE configuration manager
    #
    def configuration=(configuration)
      @configuration = configuration
      each_plugin {|plugin| plugin.configuration = configuration}
      #add plugin to represent the subsystem itself
      add_plugin do |plugin|
        plugin.name = @name
        plugin.version = @version
        plugin.require_path = nil #"freebase/plugin"
        plugin.startup_module = "FreeBASE::SubsystemPlugin"
        plugin.autoload = true
        @plugins.each do |other|
          plugin.add_load_dependency(other.name)
        end
        @plugins.each do |other|
          plugin.add_start_dependency(other.name)
        end
      end
    end
    
    ##
    # Returns a newly created plugin accepting an optional block
    # which can be used to set attributes of the plugin
    #
    # &block:: [Block] Accepts the yielded plugin as the parameter
    def add_plugin(&block)
      plugin = PluginConfiguration.new(&block)
      plugin.configuration = @configuration
      @plugins << plugin
      plugin
    end
    
    ##
    # Iterates over the list of available plugins yielding each one
    #
    def each_plugin
      @plugins.each {|plugin| yield plugin}
    end
    
  end
  
  ##
  # This class holds the metadata about a plugin.  It is created
  # by a Reader (see reader.rb) from either an XML file or a YAML
  # load operation.
  #
  class PluginConfiguration
  
    ##
    # Raised if there is a circular dependency in plugins during load/start
    # holds a reversing list of plugins to be able to show the cycle.
    #
    class CircularDependency < RuntimeError
      attr_reader :plugin_list
      ##
      # Constructs an exception with the supplied elements
      #
      # dep_type:: [String] Ether "load" or "start"
      # start_plugin:: [FreeBASE::PluginConfiguration] The plugin that the cycle was caught in
      def initialize(dep_type, start_plugin)
        @dep_type = dep_type.capitalize
        @plugin_list = [start_plugin]
      end
      
      ##
      # Outputs the cycle:
      #   PluginA -> PluginB -> PluginC -> PluginA
      #
      def to_s
        cycle = (@plugin_list.collect {|plugin| plugin.name}).reverse.join("->")
        "\n#{@dep_type} Circular Plugin Dependency: #{cycle}"
      end
    end
    
    attr_accessor(:name, :version, :require_path, 
                  :properties_path, :startup_module, 
                  :resource_path, :base_path, 
                  :full_base_path, 
                  :description, :author, :tests, :test_module)
    attr_writer :autoload
    attr_reader :configuration
    attr_reader :fwd_load_graph, :fwd_start_graph
    attr_reader :rev_load_graph, :rev_start_graph
    attr_reader :load_level, :start_level
    
    def dependencies_met
      if @dependencies_met == nil
        true
      else
        @dependencies_met
      end
    end

    alias :dependencies_met? :dependencies_met
    
    ##
    # Contructs a plugin configuration.  Yields instance of self for initializing instance data.
    #
    def initialize
      yield self if block_given?
      @dependencies_met = true
    end
    
    ##
    # Retrieve the base path in the in the user dir (USERPROFILE or HOME)
    #
    def base_user_path
      filename = DefaultPropertiesReader.user_filename(File.join(@base_path,"foo.bar"))
      unless @base_user_path
        if filename
          require 'fileutils'
          FileUtils.mkdir_p(File.dirname(filename))
          @base_user_path = File.dirname(filename)
        end
      end
      @base_user_path
    end
    
    ##
    # Retrieve the local user file (in USERPROFILE or HOME) of the supplied filespec.
    # This method is usefull if a plugin needs to create a file
    #
    def user_filename(filespec, ensure_dir=false)
      filename = DefaultPropertiesReader.user_filename(filespec)
      if ensure_dir && filename
        require 'fileutils'
        FileUtils.mkdir_p(File.dirname(filename))
      end
    end
    
    ##
    # Orders the properties to export when this object is serialized
    # to YAML
    #
    # return:: [Array] List of properties to export...used by YAML
    #
    def to_yaml_properties
      ['@name', '@version', '@autoload', '@require_path', 
       '@startup_module', '@properties_path', 
       '@resource_path', '@load_dependencies', '@start_dependencies']
    end
    
    ##
    # Gets (and possibly builds if first time called) the FreeBASE::Plugin object
    #
    # return:: [FreeBASE::Plugin] The plugin controller for this configuration
    #
    def instance
      unless @plugin_instance
        @plugin_instance = FreeBASE::Plugin.new(@configuration.core, self)
      end
      @plugin_instance
    end
    
    ##
    # Builds a graph of dependencies (both forward and reverse) which is used to 
    # detect cycles and block loading/starting of plugins whose dependent plugin
    # fails
    #
    def build_graph
      each_load_dependency do |other, version|
        other_plugin = @configuration.plugins[other]
        unless other_plugin
          puts "#{@name} has a load dependency not found: #{other}"
          @dependencies_met = false
          return false
        end
        @fwd_load_graph << other_plugin
        other_plugin.rev_load_graph << self
      end
      each_start_dependency do |other, version|
        other_plugin = @configuration.plugins[other]
        unless other_plugin
          puts "#{@name} has a start dependency not found: #{other}"
          @dependencies_met = false
          return false
        end
        return false unless other_plugin
        @fwd_start_graph << other_plugin
        other_plugin.rev_start_graph << self
      end
      return true
    end
    
    ##
    # Computes the load level and start level for this plugin configuration
    #
    def compute_levels
      get_load_level
      get_start_level
    end
    
    ##
    # Returns the load level for this plugin configuration.  This will always
    # be one higher than the highest level plugin which this plugin is dependent
    # on.  This method may raise a CircularDependency exception if on is detected.
    # 
    # return:: [Integer] The load level
    #
    def get_load_level
      raise (CircularDependency.new("Load", self)) if @computing_levels
      return @load_level if @load_level
      @computing_levels = true
      @load_level = 0
      @fwd_load_graph.each do |other|
        begin
          olevel = other.get_load_level + 1
        rescue CircularDependency => cycle
          cycle.plugin_list << self
          raise
        end
        @load_level = olevel unless @load_level > olevel
      end
      @computing_levels = false
      return @load_level
    end
    
    ##
    # Returns the start level for this plugin configuration.  This will always
    # be one higher than the highest level plugin which this plugin is dependent
    # on.  This method may raise a CircularDependency exception if on is detected.
    # 
    # return:: [Integer] The start level
    #
    def get_start_level
      raise (CircularDependency.new("Start", self)) if @computing_levels
      return @start_level if @start_level
      @computing_levels = true
      @start_level = 0
      @fwd_start_graph.each do |other|
        begin
          olevel = other.get_start_level + 1
        rescue CircularDependency => cycle
          cycle.plugin_list << self
          raise
        end
        @start_level = olevel if @start_level < olevel
      end
      @computing_levels = false
      return @start_level
    end
    
    ##
    # Sets the configuration controller for this plugin config.
    #
    # configuration:: [FreeBASE::Configuration] The configuration controller instance
    #
    def configuration=(configuration)
      @fwd_load_graph = []
      @fwd_start_graph = []
      @rev_load_graph = []
      @rev_start_graph = []
      @configuration = configuration
    end
    
    ##
    # Returns whether this plugin should automatically load and start
    #
    # return:: [Boolean] True if this plugin should load and start, otherwise false
    #
    def autoload?
      @autoload
    end
    
    ##
    # Returns instance of self
    #
    def each_plugin
      yield self
    end
    
    ##
    # Add a load dependency for this plugin
    #
    # plugin:: [String] The plugin name that this plugin is dependent on to load
    # version:: [String="*"] The version of the plugin that this plugin is dependent on (* for any)
    #
    def add_load_dependency(plugin, version="*")
      @load_dependencies ||= {}
      @load_dependencies[plugin]=version
    end
    
    ##
    # Add a start dependency for this plugin
    #
    # plugin:: [String] The plugin name that this plugin is dependent on to start
    # version:: [String="*"] The version of the plugin that this plugin is dependent on (* for any)
    #
    def add_start_dependency(plugin, version="*")
      @start_dependencies ||= {}
      @start_dependencies[plugin]=version
    end
    
    ##
    # Iterates over each load dependency yielding a |plugin, version| for each iteration.
    #
    def each_load_dependency(&block)
      return unless @load_dependencies
      @load_dependencies.each(&block)
    end
    
    ##
    # Iterates over each start dependency yielding a |plugin, version| for each iteration.
    #
    def each_start_dependency(&block)
      return unless @start_dependencies
      @start_dependencies.each(&block)
    end
  end
end


