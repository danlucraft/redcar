# Purpose: FreeBASE properties Manager. 
#    
# $Id: properties.rb,v 1.6 2005/02/27 16:18:29 ljulliar Exp $
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
  # The Properties class sits on top of the databus
  # and persists the tree of values in an xml file
  #
  class Properties
    attr_reader :base_slot
    attr_accessor :auto_save
    
    ##
    # test if a property file exists either in the user
    # or the FR directory
    #
    def self.exist?(filespec)
      user_filespec = DefaultPropertiesReader.user_filename(filespec)
      if user_filespec.nil?
        filespec = File.join($FR_CODEBASE,filespec) unless File.absolute_path?(filespec)
      else
        filespec = user_filespec
      end
      File.exist?(filespec)
    end

    ##
    # Copy a property file from source file to target file
    # Try to copy to user directory first else FR directory
    #
    def self.copy(filespec_src, filespec_tgt)
      require 'ftools'
      user_filespec_tgt = DefaultPropertiesReader.user_filename(filespec_tgt)
      if user_filespec_tgt.nil?
        filespec_tgt = File.join($FR_CODEBASE,filespec_tgt) unless File.absolute_path?(filespec_tgt)
      else
        filespec_tgt = user_filespec_tgt
      end
      filespec_src = File.join($FR_CODEBASE,filespec_src) unless File.absolute_path?(filespec_src)
      File.makedirs(File.dirname(filespec_tgt))
      File.copy(filespec_src, filespec_tgt)
    end
  
    ##
    # Creates a new Properties
    #
    # name:: [String] The name of this properties file
    # version:: [String] The version of this properties file
    # base_slot:: [FreeBASE::DataBus::Slot] The base slot of the branch to persist
    # filespec:: [String] The file to store the properties in
    #
    def initialize(name, version, base_slot, filespec)
      @base_slot = base_slot
      @filespec = filespec
      @name = name
      @version = version
      @auto_save = true
      @base_slot.propagate_notifications = false
      begin
	DefaultPropertiesReader.load(@base_slot, @filespec)
      rescue
	@base_slot["/log/error"] << "Error loading property file: #{filespec}. Error: #{$!}. Ignoring it!"
      end
      @base_slot.propagate_notifications = true
      @base_slot.manager = self
      @base_slot.subscribe self
    end
    
    ##
    # Event handler for Slot change notifications
    # see:: FreeRIDE::DataBus::Slot
    #
    def databus_notify(event, slot)
      save if event == :notify_data_set && @auto_save
    end
    
    def prune(path)
      @base_slot[path].prune
      save
    end
    
    ##
    # Gets the property value
    #
    # path:: [String] the property path
    # return:: [String] the property value
    #
    def [](path)
      return @base_slot[path].data
    end
    
    ##
    # Sets the property value and persists the properties
    #
    # path:: [String] the property path
    # value:: [to_s] the property value
    #
    def []=(path, value)
      @base_slot[path].data = value
    end
    
    def each_property(path=".")
      @base_slot[path].each_slot do |slot|
        yield slot.name, slot.data
      end
    end
    
    ##
    # Persists the properties file using the defined PropertiesReader
    #
    def save
      DefaultPropertiesReader.save(@base_slot, @filespec, @name, @version)
    end

  end
end
