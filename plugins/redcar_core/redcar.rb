#! /usr/bin/env ruby

$KCODE = "U"
$REDCAR_ENV ||= {}
$REDCAR_ENV["test"] = false

$: << File.dirname(__FILE__)
$: << File.dirname(__FILE__) + "/../../vendor"

print "loading gems..."
require 'rubygems'
require 'gtk2'
require 'gconf2'
require 'libglade2'
require 'fileutils'
require 'uuid'
require 'open3'
require 'active_support'
require 'oniguruma'
puts "done"

print "loading lib..."
require 'core/menus'
require 'core/command'
require 'core/preferences'
require 'core/plugin'

require 'vendor/ruby_extensions'
require 'vendor/keyword_processor'
require 'vendor/instruments'

require 'core/plist'
require 'core/application'
require 'core/events'
require 'core/undoable'
require 'core/sensitivity'
#require 'core/keymap'
require 'core/toolbars'
require 'core/tabs'
require 'core/file'
require 'core/icons'
require 'core/dialog'
require 'core/speedbar'
require 'core/statusbar'
require 'core/clipboard'
require 'core/textentry'
require 'core/texttab'
require 'core/tooltips'
require 'core/shelltab'
require 'core/panes'
require 'core/redcar_window'
require 'core/list_abstraction'
require 'core/button_text_tab'
require 'core/html_tab'


#require 'vendor/mdi5'

puts "done"

module Redcar
  VERSION = '0.0.1'
  class << self
    attr_accessor :current_window, :keycatcher, :image
        
    def add_objects
      Redcar.keycatcher = Redcar::KeyCatcher.new
      Redcar.current_window = Redcar::RedcarWindow.new
    end
    
    def show_time
      st = Time.now
      yield
      en = Time.now
      puts "done in #{en-st} seconds"
    end
    
    def load_stuff(options)
      print "loading menus ..."; $stdout.flush
      show_time do
        Redcar::Menu.draw_menus
        Redcar::Toolbar.draw_toolbars
      end
      
      puts Redcar::Keymap.all      
      
      if options[:load_scripts]
        print "loading scripts ..."; $stdout.flush
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
    
    def main_startup(options={})
      options = process_params(options,
                               { :load_scripts => true,
                                 :output => :debug  })
      
      add_objects
      load_stuff(options)
      Redcar.output_style = options[:output]
      Redcar.current_window.show_window
      
      Redcar.event :startup
    end
    attr_accessor :CUSTOM_DIR
    attr_accessor :ROOT_PATH
  end
end

Redcar.CUSTOM_DIR = File.expand_path(File.dirname(__FILE__) + "/../../custom") 
Redcar.ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../../") 

