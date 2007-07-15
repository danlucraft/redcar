#! /usr/bin/env ruby

$KCODE = "U"
$REDCAR_ENV ||= {}
$REDCAR_ENV["test"] = false

require "ruby2cext/eval2c" 
$e2c = Ruby2CExtension::Eval2C.new

require 'gtk2'
require 'gconf2'
require 'libglade2'
require 'fileutils'
require 'uuid'

require 'vendor/active_support'
require 'vendor/null'
require 'vendor/ruby_extensions'
require 'vendor/debugprinter'
require 'vendor/keyword_processor'
require 'vendor/instruments'

require 'lib/plist'
require 'lib/preferences_dialog.rb'
require 'lib/application'
require 'lib/undoable'
require 'lib/command'
require 'lib/sensitivity'
require 'lib/menus'
require 'lib/keymap'
require 'lib/toolbars'
require 'lib/tabs'
require 'lib/file'
require 'lib/icons'
require 'lib/dialog'
require 'lib/speedbar'
require 'lib/statusbar'
require 'lib/clipboard'
require 'lib/textentry'
require 'lib/texttab'
require 'lib/tooltips'
require 'lib/shelltab'
require 'lib/panes'
require 'lib/redcar_window'
require 'lib/list_abstraction'
require 'lib/menu_edit_tab.rb'
require 'lib/button_text_tab.rb'
require 'lib/sourceview/sourceview'
Redcar::SyntaxSourceView.init(:bundles_dir => "textmate/Bundles/",
                              :themes_dir  => "textmate/Themes/",
                              :cache_dir   => "cache/")
require 'lib/texttab_syntax'
require 'lib/html_tab'
require 'vendor/mdi5'

require 'lib/plugin.rb'

module Redcar
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
    
    def load_stuff(options)
      print "loading menus/ ..."; $stdout.flush
      Redcar::Menu.load_menus
      Redcar::Menu.create_menus
      
      print "loading scripts/ ..."; $stdout.flush
      if options[:load_scripts]
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
      puts "done"
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
