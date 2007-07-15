#! /usr/bin/env ruby

$KCODE = "U"
$REDCAR_ENV ||= {}
$REDCAR_ENV["test"] = false

require "ruby2cext/eval2c" 
$e2c = Ruby2CExtension::Eval2C.new

print "loading gems..."
require 'gtk2'
require 'gconf2'
require 'libglade2'
require 'fileutils'
require 'uuid'
puts "done"

print "loading lib..."
require 'vendor/active_support'
require 'vendor/null'
require 'vendor/ruby_extensions'
require 'vendor/debugprinter'
require 'vendor/keyword_processor'
require 'vendor/instruments'

require 'lib/image/image'

require 'lib/redcar/plist'
require 'lib/redcar/preferences_dialog.rb'
require 'lib/redcar/application'
require 'lib/redcar/undoable'
require 'lib/redcar/command'
require 'lib/redcar/sensitivity'
require 'lib/redcar/menus'
require 'lib/redcar/keymap'
require 'lib/redcar/toolbars'
require 'lib/redcar/tabs'
require 'lib/redcar/file'
require 'lib/redcar/icons'
require 'lib/redcar/dialog'
require 'lib/redcar/speedbar'
require 'lib/redcar/statusbar'
require 'lib/redcar/clipboard'
require 'lib/redcar/textentry'
require 'lib/redcar/texttab'
require 'lib/redcar/tooltips'
require 'lib/redcar/shelltab'
require 'lib/redcar/panes'
require 'lib/redcar/redcar_window'
require 'lib/redcar/list_abstraction'
require 'lib/redcar/menu_edit_tab.rb'
require 'lib/redcar/button_text_tab.rb'
require 'lib/sourceview/sourceview'
Redcar::SyntaxSourceView.init(:bundles_dir => "textmate/Bundles/",
                              :themes_dir  => "textmate/Themes/",
                              :cache_dir   => "cache/")
require 'lib/redcar/texttab_syntax'
require 'lib/redcar/html_tab'
require 'vendor/mdi5'

require 'lib/redcar/plugin.rb'

puts "done"

module Redcar
  VERSION = '0.0.1'
  class << self
    attr_accessor :current_window, :keystrokes
        
    def add_objects
      Redcar.keystrokes = Redcar::Keystrokes.new
      Redcar.window_controller = Gtk::MDI::Controller.new(RedcarWindow, :notebooks)
      Redcar.windows ||= []
      Redcar.windows << Redcar.window_controller.open_window
      Redcar.current_window = Redcar.windows.first
      Redcar.moz = Gtk::MozEmbed.new
     # Redcar.moz.sensitive = false
    end
    
    def show_time
      st = Time.now
      yield
      en = Time.now
      puts "done in #{en-st} seconds"
    end
    
    def load_stuff(options)
      print "loading menus/ ..."; $stdout.flush
      show_time do
        Redcar::Menu.load_menus
        Redcar::Menu.create_menus
      end
      
      if options[:load_scripts]
        print "loading scripts/ ..."; $stdout.flush
        show_time do
          Dir.glob("scripts/*/*.rb").sort.each do |f|
            if File.file?(f) and not f.include? "~"
              require f
            end
          end
          Dir.glob("scripts/*.rb").sort.each do |f|
            if File.file?(f) and not f.include? "~"
              require f
            end
          end
        end
      end
    end
    
    def startup(options={})
      options = process_params(options,
                               { :load_scripts => true,
                                 :output => :debug  })
      
      add_objects
      load_stuff(options)
      Redcar.output_style = options[:output]
      Redcar.current_window.show_window
      Redcar.moz.show_all
      
      Redcar.event :startup
    end
    attr_accessor :CUSTOM_DIR
    attr_accessor :ROOT_PATH
  end
end

Redcar.CUSTOM_DIR = File.expand_path(File.dirname(__FILE__) + "/../custom") 
Redcar.ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../") 
