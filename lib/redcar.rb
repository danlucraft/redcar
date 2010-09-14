
$:.push(File.expand_path(File.join(File.dirname(__FILE__))))
$:.push(File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor spoon lib})))
$:.push(File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor ffi lib})))

require 'redcar/usage'

require 'redcar/ruby_extensions'
require 'redcar/instance_exec'
require 'redcar/usage'
require 'regex_replace'

require 'forwardable'
require 'uri'

begin
  if Config::CONFIG["RUBY_INSTALL_NAME"] == "jruby"
    require 'spoon'
    module Redcar; SPOON_AVAILABLE = true; end
  else
    module Redcar; SPOON_AVAILABLE = false; end
  end
rescue LoadError
  module Redcar; SPOON_AVAILABLE = false; end
end

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
  VERSION         = '0.6dev' # also change in the Rakefile!
  VERSION_MAJOR   = 0
  VERSION_MINOR   = 6
  VERSION_RELEASE = 0
  
  ENVIRONMENTS = [:user, :debug, :test]
  
  PROCESS_START_TIME = Time.now
  
  ICONS_DIRECTORY = File.expand_path(File.join(File.dirname(__FILE__), %w{.. share icons}))

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
    require 'redcar/runner'
    runner = Redcar::Runner.new
    runner.run
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

  def self.load_prerequisites
    exit if ARGV.include?("--quit-immediately")
    
    require 'redcar_quick_start'
    
    $:.push File.expand_path(File.join(File.dirname(__FILE__), "plugin_manager", "lib"))
    require 'plugin_manager'
    
    $:.push File.expand_path(File.join(File.dirname(__FILE__), "json", "lib"))
    require 'json'
    
    $:.push File.expand_path(File.join(Redcar.asset_dir))
    
    $:.push File.expand_path(File.join(File.dirname(__FILE__), "openssl", "lib"))
    
    plugin_manager.load("swt")
  end

  def self.load_plugins
    begin
      exit if ARGV.include?("--quit-after-splash")
      
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
    rescue => e
      puts e.message
      puts e.backtrace
    end
  end
  
  # Tells the plugin manager to load plugins, and prints debug output.
  def self.load_threaded
    load_prerequisites
    thread = Thread.new do
      load_plugins
      Redcar::Top.start(ARGV)
    end
    if no_gui_mode?
      thread.join
    end
  end
  
  def self.load_unthreaded
    load_prerequisites
    load_plugins
  end
  
  def self.no_gui_mode?
    ARGV.include?("--no-gui")
  end
  
  def self.show_splash
    return if Redcar.no_gui_mode?
    
    Swt.create_splash_screen(plugin_manager.plugins.length + 10)
    plugin_manager.on_load do |plugin|
      Swt.sync_exec do
        Swt.splash_screen.inc
      end
    end
  end

  ## Starts the GUI.
  def self.pump
    return if Redcar.no_gui_mode?
    
    Redcar.gui.start
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
    File.expand_path(File.join(home_dir, dirname))
  end
  
  # Platform specific ~/.redcar/assets
  def self.asset_dir
    File.join(home_dir, ".redcar", "assets")
  end
  
  # Platform specific ~/
  #
  # @return [String] expanded path
  def self.home_dir
    if platform == :windows
      if ENV['USERPROFILE'].nil?
        userdir = "C:/My Documents/"
      else
        userdir = ENV['USERPROFILE']
      end
    else
      userdir = ENV['HOME'] unless ENV['HOME'].nil?
    end
  end
  
  class << self
    attr_accessor :app
    attr_reader :gui
  end
  
  # Set the application GUI.
  def self.gui=(gui)
    raise "can't set gui twice" if @gui
    return if Redcar.no_gui_mode?
    @gui = gui
  end
end

usage = Redcar::Usage.new
usage.version_string
usage.version_requested
usage.help_requested
