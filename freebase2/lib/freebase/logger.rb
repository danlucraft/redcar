# Purpose: Sample logger plugin
#    
# $Id: logger.rb,v 1.2 2003/06/24 05:00:43 richkilmer Exp $
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
  module Plugins
    class Logger
    
      class SimpleFileLogger
        LEVELS = ['disabled', 'error', 'info', 'debug']
        def initialize(logName, logFile, logLevel)
          @logName = logName
          @logFile = logFile
          ensure_logdir
          self.logLevel = logLevel
          @file = File.new(logFile, "a")
          @file.sync = true
        end
        
        def ensure_logdir
          path = File.dirname(@logFile).split(File::SEPARATOR)
          (path.size-1).times do |i|
            dir = File.join(*path[0,i+2])
            unless File.exist?(dir)
              Dir.mkdir(dir)
            end
          end
        end
        
        def logLevel=(logLevel)
          logLevel = LEVELS[logLevel] if logLevel.kind_of? Numeric
          @logLevel = logLevel.downcase
          case @logLevel
          when 'disabled'
            @logLevelInt = 0
          when 'error'
            @logLevelInt = 1
          when 'info'
            @logLevelInt = 2
          when 'debug'
            @logLevelInt = 3
          else
            raise "Unknown Logger level: #{@logLevel}"
          end
        end
        
        def close
          @file.close
        end
        
        def time
          Time.now.strftime("%Y-%m-%d %H:%M:%S")
        end
        
        def error(message)
          return if @logLevelInt < 1
          @file.puts "#{time} :: [ERROR] #{message}"
        end
        
        def info(message)
          return if @logLevelInt < 2
          @file.puts "#{time} :: [INFO]  #{message}"
        end
        
        def debug(message)
          return if @logLevelInt < 3
          @file.puts "#{time} :: [DEBUG] #{message}"
        end

      end
    
      extend FreeBASE::StandardPlugin
    
      def self.start(plugin)
        begin
          system_properties = plugin["/system/properties"].manager
          logName = system_properties["config/log_name"]
          logFile = system_properties["config/log_file"]
          # Create log file in user directory if it exists
          user_logFile = DefaultPropertiesReader.user_filename(logFile)
          if !user_logFile.nil?
            logFile = user_logFile
          end
          logLevel = system_properties["config/log_level"]        
          logger = SimpleFileLogger.new(logName, logFile, logLevel)
          ["info", "error", "debug"].each do |logType| #clear the existing log entries
            while msg = plugin["/log/#{logType}"].queue.leave
              logger.send(logType, msg)
            end
          end
          plugin["close"].set_proc { logger.close }
          plugin["set_level"].set_proc{ |level| logger.logLevel = level }
          plugin["/log"].set_proc { |logType, message| logger.send(logType, message) }
          plugin["/log"].manager = logger
          plugin.transition(FreeBASE::RUNNING)
        rescue
          puts $!
          puts $!.backtrace.join("\n")
          plugin.transition_failure
        end
      end
    end
    
  end
end
