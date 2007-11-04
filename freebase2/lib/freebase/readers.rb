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
begin
  require 'rubygems'
rescue
end

module FreeBASE

  ##
  # Reads and writes properties (properties.rb) to a persistent file in YAML
  #
  class YAMLPropertiesReader

    @@userdir = nil
  
    def self.load_libraries
      require 'yaml'
    end
    
    ##
    # Determine where the user directory is (if any)
    #
    def self.setup
      $FREEBASE_APPLICATION = "redcar" unless $FREEBASE_APPLICATION
      if RUBY_PLATFORM =~ /(mswin32|mingw32)/
        if ENV['USERPROFILE'].nil?
          @@userdir = "C:/My Documents/.redcar/"
          Dir.mkdir(@@userdir) unless File.directory?(@@userdir)
        else
          @@userdir = File.join(ENV['USERPROFILE'], $FREEBASE_APPLICATION)
        end
      else
        @@userdir = File.join(ENV['HOME'],".#{$FREEBASE_APPLICATION}") unless ENV['HOME'].nil?
      end
    end

    ##
    # Given a relative path to a property file, return the full path 
    # in the user directory. Return nil if no user directory defined
    # or absolute path name given.
    #
    def self.user_filename(filespec)
      return nil if @@userdir.nil? || File.absolute_path?(filespec)
      return File.expand_path(File.join(@@userdir,filespec))
    end

    ##
    # Save a property file. Try in the user directory first then in the
    # FR directory
    #
    def self.save(base_slot, filespec, name, version)
      user_filespec = user_filename(filespec)
      if user_filespec.nil?
        filespec = File.join($FR_CODEBASE,filespec) unless File.absolute_path?(filespec)
      else
        filespec = user_filespec
        # if file first saved make sure to create the full path first
        unless File.exist?(filespec)
          require 'ftools'
          File.makedirs(File.dirname(filespec))
        end
      end
      # puts ">>> Saving Property File: #{filespec}"
      file = File.new(filespec,  "w+")
      file.puts "#### Properties: #{name} - Version: #{version}"
      file.puts gather_data(base_slot).to_yaml(:SortKeys=>true)
      file.close
    end
    
    def self.gather_data(slot, structure={})
      structure[slot.name]=slot.data
      if slot.has_child?
        structure['|'] = Array.new
        slot.each_slot do |child_slot|
          map = {}
          structure['|'] << map
          gather_data(child_slot, map)
        end
      end
      structure
    end
    
    ##
    # Load a property file. Try in the user directory first then in the
    # FR directory
    #
    def self.load(base_slot, filespec)
      user_filespec = user_filename(filespec)
      if !user_filespec.nil? && File.exist?(user_filespec)
        filespec = user_filespec
      else
        filespec = File.join($FR_CODEBASE,filespec) unless File.absolute_path?(filespec)
      end
      #puts "Loading Property File: #{filespec}"
      return unless File.exist?(filespec)
      data = nil
      File.open(filespec) {|file| data = file.read}
      map = YAML.load(data)
      if map != nil
        read_slot(base_slot, map)
      end
    end
    
    def self.read_slot(slot, map)
      slot.data = map[map.keys.sort[0]]
      return unless map["|"]
      map['|'].each do |subslotmap|
        read_slot(slot[subslotmap.keys.sort[0]], subslotmap)
      end
    end
  end
  
  ##
  # Reads and writes properties (properties.rb) to a persistent file in XML
  #
  class REXMLPropertiesReader
  
    def self.load_libraries
      require 'rexml/document'
    end
    
    def self.save(base_slot, filespec, name, version)
      file = File.new(filespec,  "w+")
      doc = REXML::Document.new "<properties name='#{name}' version='#{version}'/>"
      base_slot.each_slot { |slot| write_slot(slot, doc.root) }
      doc.write  file
      file.close
    end
    
    def self.write_slot(slot, root)
      n_element = root.add_element("slot", {"name"=>slot.name})
      n_element.text = slot.data
      slot.each_slot { |child| write_slot(child, n_element) }
    end
    
    def self.load(base_slot, filespec)
      return unless File.exist?(filespec)
      file = File.new(filespec)
      doc = REXML::Document.new(file)
      doc.root.each_element("slot") { |element| read_slot(base_slot, element) }
      file.close
    end
      
    def self.read_slot(root, element)
      slot = root[element.attributes["name"]]
      slot.data = element.text.strip if element.text
      element.each_element("slot") { |element| read_slot(slot, element) }
    end
  end
  
  ##
  # Reads the configuration files from the plugin path and registers the plugins
  # with the Configuration (manager).
  #
  class YAMLConfigurationReader
    def initialize(configuration)
      @configuration = configuration
      load_files
    end
    
    def load_files
      paths = @configuration.plugin_paths.split(";")
      if defined? Gem
        gems = Gem::SourceIndex.from_installed_gems(File.join(Gem.dir, "specifications"))
        gems.each do |path, gem|
          if gem.summary.include? "(#{$FREEBASE_APPLICATION} plugin)"
            paths << Gem.dir+"/gems/"+path
          end
        end
      end
      load_files_from_paths(paths)
    end
    
    private
    
    def load_files_from_paths(paths)
      paths.each do |path|
        fullpath = path
        fullpath = File.join($FR_CODEBASE,path) unless File.absolute_path?(fullpath)
        Dir.foreach(fullpath) do |file|
          next if file=='..' || file=='.'
          if File.stat("#{fullpath}/#{file}").directory?
            full_filespec = "#{fullpath}/#{file}/plugin.yaml"
            filespec = "#{path}/#{file}/plugin.yaml"
            next unless File.exist?(full_filespec)
            @configuration.register(YAML.load(File.open(full_filespec).read),
                                    File.dirname(filespec))
          elsif file[-5..-1]==".yaml" and !File.stat("#{fullpath}/#{file}").directory?
            full_filespec = "#{fullpath}/#{file}"
            filespec = "#{path}/#{file}"
            
            # we absolutize the path here for gem plugins
            yaml_spec = YAML.load(File.open(full_filespec).read)
            yaml_spec.require_path = fullpath+"/"+yaml_spec.require_path
            @configuration.register(yaml_spec,
                                    File.dirname(filespec))
          end
        end
      end
    end
  end
  
  # NOTE: NOT YET COMPLETE
  class REXMLConfigurationReader
  
    def initialize(configuration)
      raise "The REXMLConfigurationReader is incomplete at this time"
      @configuration = configuration
      load_files
    end
  
    ##
    # Iterates over the directory(s) defined in the properties["/config/plugin_path"]
    # looking for subdirectories. When found, the plugin.xml file is read and the 
    # identified file is "required" and the identified module has startup(bus,localbus) 
    # called upon it.
    #
    def process_configuration_files(configuration)
      plugin_element = nil
      configuration.plugin_paths.split(";").each do |path|
        Dir.foreach(path) do |file|
          if file!=".." and file!="." and File.stat("#{path}/#{file}").directory?
            filespec = "#{path}/#{file}/plugin.xml"
            next unless File.exist?(filespec)
            each_plugin_element(filespec) do |plugin_element| 
              FreeBASE::Plugin.new(self, filespec, plugin_element)
            end
          elsif file[-4..-1]==".xml" and !File.stat("#{path}/#{file}").directory?
            filespec = "#{path}/#{file}"
            each_plugin_element(filespec) do |plugin_element| 
              FreeBASE::Plugin.new(self, filespec, plugin_element)
            end
          end
        end
      end
    end
    ##
    # Opens the supplied file and parse <plugin> elements
    # yielding each to the supplied block.
    #
    # filespec:: [String] The file name to parse
    # &block:: [String] The block to be yielded the REXML element
    #
    def each_plugin_element(filespec, &block)
      file = File.new(filespec)
      xml = REXML::Document.new file
      file.close
      plugin_element = xml.root
      if plugin_element.name=="plugin"
        yield plugin_element
        return
      else
        yield plugin_element if plugin_element.attributes["name"] #register subsystem plugin
        plugin_element.each_element("plugin") {|element| yield element}
      end
    end
    
    
    def parse_xml(plugin_element)
      if plugin_element.name=="subsystem"
        @name = plugin_element.attributes["name"]
        @version = "1.0"
        @autoload=true
        @startup_module = "FreeBASE::SubsystemPlugin"
        @dependencies = {}
        dependency = Dependency.new("LOADED", "start")
        plugin_element.each_element("plugin") do |element|
          dependency.add_plugin(element.attributes["name"], "*", "RUNNING")
        end
        @dependencies["LOADED"] = dependency
      else
        @name = plugin_element.attributes["name"]
        @version = plugin_element.attributes["version"]
        @autoload = plugin_element.attributes["autoload"]=="true" ? true : false
        @require_file = plugin_element.elements["require"].text
        @startup_module = plugin_element.elements["module"].text
        if plugin_element.elements["resourcePath"]
          @resource_path = plugin_element.elements["resourcePath"].text
        end
        if plugin_element.elements["properties"]
          @properties_file = plugin_element.elements["properties"].text
        end
        @dependencies = {}
        plugin_element.each_element("dependency") do |element|
          dependency = Dependency.new(element.attributes["state"], element.attributes["action"])
          element.each_element("when") do |pelement|
            attr = pelement.attributes
            dependency.add_plugin(attr["plugin"], attr["version"], attr["state"])
          end
          @dependencies[element.attributes["state"]] = dependency
        end
      end
    end
    
  end
  
  # This represents the PropertiesReader and ConfigurationReader
  # It is important that these be set either to YAML or REXML.
  DefaultPropertiesReader = YAMLPropertiesReader
  DefaultPropertiesReader.load_libraries
  DefaultPropertiesReader.setup  
  DefaultConfigurationReader = YAMLConfigurationReader
 
end


