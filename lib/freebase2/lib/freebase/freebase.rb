# Purpose: FreeBASE constant declarations and module inclusion
#    
# $Id: freebase.rb,v 1.3 2003/07/16 21:07:08 ljulliar Exp $
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

  #version information
  VERSION_MAJOR = 0
  VERSION_MINOR = 1
  VERSION_RELEASE = 0

  #state transitions for plugins
  UNLOADED = "UNLOADED"
  LOADING = "LOADING"
  LOADED = "LOADED"
  STARTING = "STARTING"
  RUNNING = "RUNNING"
  STOPPING = "STOPPING"
  UNLOADING = "UNLOADING"
  ERROR = "ERROR"
  
  #system state transition order
  STARTUP_STATES = [UNLOADED, LOADING, LOADED, STARTING, RUNNING]
  SHUTDOWN_STATES = [STOPPING, LOADED, UNLOADING, UNLOADED]

end

##
# Test whether a file path is absolute or relative
# (used in several method of freebase to load/store
#  plugin config files
#
class File
  def File.absolute_path?(path)
    if RUBY_PLATFORM =~ /(mswin32|mingw32)/
      path =~ %r{^([a-zA-Z]:)*[/\\]+}
    else
      path[0..0] == File::SEPARATOR
    end
  end
end

require File.dirname(__FILE__) + '/core'
require File.dirname(__FILE__) + '/plugin'
require File.dirname(__FILE__) + '/databus'
require File.dirname(__FILE__) + '/properties'
require File.dirname(__FILE__) + '/readers'
require File.dirname(__FILE__) + '/configuration'
