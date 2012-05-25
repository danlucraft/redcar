
$:.push(File.expand_path(File.join(File.dirname(__FILE__))))

require 'redcar/usage'

require 'redcar/ruby_extensions'
require 'redcar/instance_exec'
require 'redcar/usage'
require 'redcar/logger'
require 'regex_replace'

require 'forwardable'
require 'uri'
require 'fileutils'
require 'net/http'
require 'yaml'

class RedcarIcons
  def self.directory
    File.expand_path("../../assets/fugue-icons", __FILE__)
  end
end

module RedcarBundles
  def self.dir
    File.expand_path("../../assets/textmate", __FILE__)
  end
end

begin
  if Config::CONFIG["RUBY_INSTALL_NAME"] == "jruby"
=begin
    gem "spoon"
    require 'spoon'
    module Redcar; SPOON_AVAILABLE = true; end
  else
=end
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
  VERSION         = '0.14.0dev' # also change in the gemspec!
  VERSION_MAJOR   = 0
  VERSION_MINOR   = 14
  VERSION_RELEASE = 0

  ENVIRONMENTS = [:user, :debug, :test]

  PROCESS_START_TIME = Time.now

  def self.icons_directory
    RedcarIcons.directory
  end

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
      add_plugin_sources(m)
      m.disabled_plugins = disabled_plugins
      m
    end
  end

  def self.add_plugin_sources(manager)
    manager.add_plugin_source(File.join(root, "plugins"))
    manager.add_plugin_source(File.join(user_dir, "plugins"))
  end

  def self.load_prerequisites(options={})
    exit if ARGV.include?("--quit-immediately")
    require 'java'
    
    require 'redcar_quick_start'
    vendor_path = File.expand_path("../../vendor", __FILE__)
    require "#{vendor_path}/bundler/setup.rb"
    require 'plugin_manager'

    unless defined?(JSON)
      $:.unshift("#{vendor_path}/json-1.6.4-java/lib")
      require 'json'
    end

    require 'bouncy-castle-java'
    require 'openssl'
    plugin_manager.load("core")
    require 'swt/minimal'
      
    unless no_gui_mode?
      gui = Redcar::Gui.new("swt")
      gui.register_event_loop(Swt::EventLoop.new)
      gui.register_features_runner(Swt::CucumberRunner.new)
      Redcar.gui = gui
    
      plugin_manager.load("splash_screen")
    end
  end
  
  def self.load_plugins
    begin
      exit if ARGV.include?("--quit-after-splash")
      
      plugin_manager.load
      
      if plugin_manager.unreadable_definitions.any?
        puts "Couldn't read definition files:  " + plugin_manager.unreadable_definitions.map {|pd| pd.name}.join(", ")
      end
      if plugin_manager.plugins_with_errors.any?
        puts "There was an error loading plugins:  " + plugin_manager.plugins_with_errors.map {|pd| pd.name}.join(", ")
      end
      if ENV["PLUGIN_DEBUG"]
        puts "Loaded plugins:  " + plugin_manager.loaded_plugins.map {|pd| pd.name}.join(", ")
        puts
        puts "Unloaded plugins:  " + plugin_manager.unloaded_plugins.map {|pd| pd.name}.join(", ")
      end
    rescue => e
      puts e.message
      puts e.backtrace
    end
  end

  # Pulls the list of plugins the user has selected to disable from
  # storage/disabled_plugins.yaml an array of plugin name.
  def self.disabled_plugins
    return @disabled_plugins if @disabled_plugins
    path = File.join Redcar.user_dir, 'storage/disabled_plugins.yaml'
    if File.exists? path
      list = YAML.load_file path
      return @disabled_plugins = list if list.is_a? Array 
    end
    @disabled_plugins = []
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
  
  def self.load_unthreaded(options={})
    load_prerequisites(options)
    load_plugins
  end
  
  def self.no_gui_mode?
    @no_gui_mode || ARGV.include?("--no-gui")
  end
  
  def self.no_gui_mode!
    @no_gui_mode = true
  end
  
  def self.show_splash
    return if Redcar.no_gui_mode?
    unless ARGV.include?("--no-splash")
      SplashScreen.create_splash_screen(plugin_manager.plugins.length - plugin_manager.disabled_plugins.size + 10)
    end
    plugin_manager.on_load do |plugin|
      Swt.sync_exec do
        SplashScreen.splash_screen.inc if SplashScreen.splash_screen
      end
    end
  end

  ## Starts the GUI.
  def self.pump
    return if Redcar.no_gui_mode?
    
    Redcar.gui.start
  end
  
  # Check if redcar was already installed (currently it just looks if the user_dir is present)
  # 
  # @return [Bool] true if redcar was installed previously
  def self.installed?
    return true if File.directory? user_dir
    false
  end

  def self.ensure_user_dir_config
    FileUtils.mkdir_p(user_dir)
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
    @userdir ||= begin
      if arg = ARGV.map {|v| v[/^--home-dir=(.*)/, 1] }.compact.first
        File.expand_path(arg)
      elsif platform == :windows
        if ENV['USERPROFILE'].nil?
          "C:/My Documents/"
        else
          ENV['USERPROFILE']
        end
      else
        ENV['HOME'] unless ENV['HOME'].nil?
      end
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
  
  def self.log
    @log ||= begin
      targets = [log_file]
      targets << STDOUT if show_log?
      logger = Redcar::Logger.new(*targets)
      logger.level = custom_log_level
      at_exit { logger.close }
      logger
    end
  end
  
  def self.log_path
    user_dir + "/#{environment}.log"
  end
  
  def self.log_file
    File.open(log_path, "a")
  end
  
  def self.show_log?
    ARGV.include?("--show-log") or ENV["REDCAR_SHOW_LOG"]
  end
  
  def self.custom_log_level
    ARGV.map {|a| a =~ /--log-level=(info|debug|warn|error)/; $1}.compact.first
  end
  
  def self.process_start_time
    @process_start_time ||= begin
      t = ARGV.map {|arg| arg =~ /--start-time=(\d+)$/; $1}.compact.first
      t ? Time.at(t.to_i) : $redcar_process_start_time
    end
  end
end

usage = Redcar::Usage.new
usage.version_string
usage.version_requested
usage.help_requested
