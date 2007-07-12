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

require File.dirname(__FILE__) + '/../vendor/active_support'
require File.dirname(__FILE__) + '/../vendor/null'
require File.dirname(__FILE__) + '/../vendor/ruby_extensions'
require File.dirname(__FILE__) + '/../vendor/debugprinter'
require File.dirname(__FILE__) + '/../vendor/keyword_processor'
require 'vendor/instruments'

require 'lib/plist'
require 'lib/preferences_dialog.rb'
require File.dirname(__FILE__) + '/application'
require File.dirname(__FILE__) + '/undoable'
require File.dirname(__FILE__) + '/command'
require File.dirname(__FILE__) + '/sensitivity'
require File.dirname(__FILE__) + '/menus'
require File.dirname(__FILE__) + '/toolbars'
require File.dirname(__FILE__) + '/tabs'
require File.dirname(__FILE__) + '/file'
require File.dirname(__FILE__) + '/icons'
require File.dirname(__FILE__) + '/dialog'
require File.dirname(__FILE__) + '/speedbar'
require File.dirname(__FILE__) + '/statusbar'
require File.dirname(__FILE__) + '/clipboard'
require File.dirname(__FILE__) + '/textentry'
require File.dirname(__FILE__) + '/texttab'
require File.dirname(__FILE__) + '/tooltips'
require File.dirname(__FILE__) + '/shelltab'
require File.dirname(__FILE__) + '/../vendor/mdi5'
require File.dirname(__FILE__) + '/panes'
require File.dirname(__FILE__) + '/redcar_window'
require File.dirname(__FILE__) + '/list_abstraction'
require 'lib/menu_edit_tab.rb'
require 'lib/button_text_tab.rb'
require 'lib/sourceview/sourceview'
require 'lib/texttab_syntax'
require 'lib/html_tab'

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
