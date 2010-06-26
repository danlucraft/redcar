
$:.push File.expand_path(File.join(File.dirname(__FILE__)))

require 'redcar/usage'

require 'rbconfig'

require 'redcar/ruby_extensions'
require 'redcar/instance_exec'
require 'redcar/usage'
require 'regex_replace'

require 'forwardable'
require 'yaml'
require 'uri'

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
# for events from the {Redcar::Application} model and reflects them in the GUI.
#
# This structure of a model and a controller that listens to it is repeated for
# each part of Redcar reflected in the GUI.
#
#   * {Redcar::Window} has {Redcar::ApplicationSWT::Window}
#   * {Redcar::Notebook} has {Redcar::ApplicationSWT::Notebook}
#   * {Redcar::EditTab} has {Redcar::EditViewSWT::EditTab}
#
# and so on.
module Redcar
  VERSION         = '0.3.8dev'
  VERSION_MAJOR   = 0
  VERSION_MINOR   = 3
  VERSION_RELEASE = 8
  
  ENVIRONMENTS = [:user, :debug, :test]
  
  PROCESS_START_TIME = Time.now

  def self.environment=(env)
    unless ENVIRONMENTS.include?(env)
      raise "environment must be one of #{ENVIRONMENTS.inspect}"
    end
    @environment = env
  end
  
  def self.environment
    raise "no environment set" unless @environment
    @environment
  end

  def self.spin_up
    return if ARGV.include?("--no-sub-jruby")
    return if Config::CONFIG["RUBY_INSTALL_NAME"] == "jruby" and [:linux, :windows].include?(platform)
    
    require 'redcar/runner'
    runner = Redcar::Runner.new
    runner.spin_up
  end

  def self.root
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  def self.plugin_manager
    @plugin_manager ||= begin
      m = PluginManager.new
      m.add_plugin_source(File.join(root, "plugins"))
      m.add_plugin_source(File.join(user_dir, "plugins"))
      m
    end
  end

  # Tells the plugin manager to load plugins, and prints debug output.
  def self.load
    $:.push File.expand_path(File.join(File.dirname(__FILE__), "plugin_manager", "lib"))
    require 'plugin_manager'
    
    $:.push File.expand_path(File.join(File.dirname(__FILE__), "json", "lib"))
    require 'json'
    
    plugin_manager.load
    if plugin_manager.unreadable_definitions.any?
      puts "Couldn't read definition files: "
      puts plugin_manager.unreadable_definitions.map {|d| "  * " + d}
    end
    if plugin_manager.plugins_with_errors.any?
      puts "There was an error loading plugins: "
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

  # Starts the GUI.
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
    dirname = {
      :user => ".redcar",
      :test => ".redcar_test",
      :debug => ".redcar_debug"
    }[Redcar.environment]
    if platform == :windows
      if ENV['USERPROFILE'].nil?
        userdir = "C:/My Documents/#{dirname}/"
      else
        userdir = File.join(ENV['USERPROFILE'], dirname)
      end
    else
      userdir = File.join(ENV['HOME'], dirname) unless ENV['HOME'].nil?
    end
    File.expand_path(userdir)
  end
  
  class << self
    attr_accessor :app
    attr_reader :gui
  end
  
  # Set the application GUI.
  def self.gui=(gui)
    raise "can't set gui twice" if @gui
    @gui = gui
  end
end

usage = Redcar::Usage.new
usage.version_string
usage.version_requested
usage.help_requested
