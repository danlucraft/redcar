#! /usr/bin/env ruby

$KCODE = "U"
$REDCAR_ENV ||= {}
$REDCAR_ENV["test"] = false

$: << File.dirname(__FILE__)

print "loading gems..."
require 'rubygems'
require 'gtk2'
require 'gconf2'
require 'libglade2'
require 'fileutils'
require 'uuid'
require 'open3'
puts "done"

print "loading lib..."
require 'vendor/active_support'
require 'vendor/ruby_extensions'
require 'vendor/keyword_processor'
require 'vendor/instruments'

require 'image/image'

require 'redcar/plist'
require 'redcar/preferences_dialog.rb'
require 'redcar/application'
require 'redcar/undoable'
require 'redcar/command'
require 'redcar/sensitivity'
require 'redcar/menus'
require 'redcar/keymap'
require 'redcar/toolbars'
require 'redcar/tabs'
require 'redcar/file'
require 'redcar/icons'
require 'redcar/dialog'
require 'redcar/speedbar'
require 'redcar/statusbar'
require 'redcar/clipboard'
require 'redcar/textentry'
require 'redcar/texttab'
require 'redcar/tooltips'
require 'redcar/shelltab'
require 'redcar/panes'
require 'redcar/redcar_window'
require 'redcar/list_abstraction'
require 'redcar/button_text_tab.rb'
require 'sourceview/sourceview'
Redcar::SyntaxSourceView.init(:bundles_dir => "textmate/Bundles/",
                              :themes_dir  => "textmate/Themes/",
                              :cache_dir   => "cache/")
require 'redcar/texttab_syntax'
require 'redcar/html_tab'

require 'redcar/plugin'

#require 'vendor/mdi5'

puts "done"

module Redcar
  VERSION = '0.0.1'
  class << self
    attr_accessor :current_window, :keycatcher, :image
        
    def add_objects
      Redcar.keycatcher = Redcar.KeyCatcher.new
      Redcar.current_window = Redcar.RedcarWindow.new
    end
    
    def load_image
      self.image = Redcar.Image.new(:cache_dir => "environment/",
                                    :sources => ["scripts/*/image.yaml", "plugins/*/image.yaml"])
    end
    
    def show_time
      st = Time.now
      yield
      en = Time.now
      puts "done in #{en-st} seconds"
    end
    
    def load_stuff(options)
      print "loading image ..."; $stdout.flush
      show_time do
        load_image
      end
      
      Redcar.hook :shutdown do
        Redcar.image.cache
      end

      print "loading menus ..."; $stdout.flush
      show_time do
        Redcar.Menu.load_menus
        Redcar.Menu.create_menus
        Redcar.Keymap.load
      end
      
      puts Redcar.Keymap.all      
      
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
      
      p Gtk.current
    end
    attr_accessor :CUSTOM_DIR
    attr_accessor :ROOT_PATH
  end
end

Redcar.CUSTOM_DIR = File.expand_path(File.dirname(__FILE__) + "/../../custom") 
Redcar.ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../../") 

