
require 'java'

require 'redcar/ruby_extensions'
require 'redcar/instance_exec'
require 'redcar/usage'

require 'plugin_manager/lib/plugin_manager'

require 'forwardable'
require 'yaml'

# ## Loading and Initialization
#
# Every feature in Redcar is written as a plugin. This module contains a few 
# methods to bootstrap the plugins by loading the PluginManager.
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
  
  def self.root
    File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  end
  
  def self.plugin_manager
    @plugin_manager ||= begin
      m = PluginManager.new
      m.add_plugin_source(File.join(root, "plugins"))
      m.add_plugin_source(File.join(user_dir, "plugins"))
      m
    end
  end
  
  def self.load
    plugin_manager.load
    if plugin_manager.unreadable_definitions.any?
      puts "Couldn't read definition files: "
      puts plugin_manager.unreadable_definitions.map {|d| "  * " + d}
    end
    if plugin_manager.plugins_with_errors.any?
      puts "There was an error loading: "
      puts plugin_manager.plugins_with_errors.map {|d| "  * " + d.name}
    end
    if ENV["PLUGIN_DEBUG"]
      puts "Loaded plugins:"
      puts plugin_manager.loaded_plugins.map {|d| "  * " + d.name}
      puts
      puts "Unloaded plugins:"
      puts plugin_manager.unloaded_plugins.map {|d| "  * " + d.name}
      
    end
  end

  def self.pump 
    Redcar.gui.start
  end
  
  # Platform symbol
  #
  # @return [:osx/:windows/:linux]
  def self.platform
    case Config::CONFIG["target_os"]
    when /darwin/
      :osx
    when /mswin|mingw/
      :windows
    when /linux/
      :linux
    end
  end
  
  # Platform specific ~/.redcar
  #
  # @return [String] expanded path
  def self.user_dir
    if platform == :windows
      if ENV['USERPROFILE'].nil?
        userdir = "C:/My Documents/.redcar/"
      else
        userdir = File.join(ENV['USERPROFILE'], ".redcar")
      end
    else
      userdir = File.join(ENV['HOME'], ".redcar") unless ENV['HOME'].nil?
    end
    File.expand_path(userdir)
  end

end
