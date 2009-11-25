
$:.push(File.join(File.dirname(__FILE__), "..", "freebase2", "lib"))
require 'freebase/freebase'

require 'ruby_extensions'
require 'logging'

# ## Loading and Initialization
#
# Every feature in Redcar is written as a plugin. This module contains a few 
# methods to bootstrap the plugins by loading the FreeBASE plugin handler.
#
# FreeBASE (kindly open sourced by the FreeRIDE project) will load Redcar in 
# the following manner:
#
#   1. For each plugin load the file *plugin_name/lib/plugin_name.rb* and then
#      run the method "load" on the class defined in plugin.yaml as the 
#      "startup_module". The plugins will be loaded in an order respecting the
#      "load_dependencies" in each plugin.yaml.
#   2. Call the start method on each of the "startup_module" classes, respecting
#      the "start_dependencies" in each plugin.yaml
#
# All Redcar initialization is done in these methods, "load" and "start" on 
# every plugin class. Note that plugins are not required to define either of 
# these methods.
#
# Once loaded, bin/redcar will start the gui pump, which will run 
# Redcar.gui.start. This starts the GUI library's event loop and hands over 
# control to the GUI.
#
# ## Application
#
# The top class of Redcar is a {Redcar::Application}, which handles the creation 
# of Redcar::Windows. {Redcar::Application} is a good place to start
# to see how the Redcar models are created. 
#
# {Redcar::ApplicationSWT} is the start point for the SWT GUI, which listens
# for events from the Redcar::Application model and reflects them in the GUI.
#
# This structure of a model and a controller that listens to it is repeated for
# each part of Redcar reflected in the GUI.
#
#   * Redcar::Window has Redcar::ApplicationSWT::Window
#   * Redcar::Notebook has Redcar::ApplicationSWT::Notebook
#   * Redcar::EditTab has Redcar::EditViewSWT::EditTab
#
# and so on.
module Redcar
  VERSION         = '0.3.0dev'
  VERSION_MAJOR   = 0
  VERSION_MINOR   = 3
  VERSION_RELEASE = 0
  
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  $FR_CODEBASE          = File.expand_path(File.join(File.dirname(__FILE__)) + "/../")
  $FR_PROJECT           = nil
  $FREEBASE_APPLICATION = "Redcar"
  
  class << self
    attr_reader :freebase_core
  end
  
  def self.root
    ROOT
  end
  
  def self.start
    @freebase_core = FreeBASE::Core.new(*freebase_core_args)
    @freebase_core.startup
  end
  
  def self.load
    @freebase_core = FreeBASE::Core.new(*freebase_core_args)
    @freebase_core.load_plugins
  end
  
  def self.require
    @freebase_core = FreeBASE::Core.new(*freebase_core_args)
    @freebase_core.require_files
  end
  
  def self.pump
    @freebase_core.bus["/system/ui/messagepump"].call()
  end
  
  private
  
  def self.freebase_core_args
    ["properties.yaml", "config/default.yaml"]
  end
end

if ARGV.include?("-v")
  puts "Redcar #{Redcar::VERSION}"
  exit
end