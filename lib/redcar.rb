#! /usr/bin/env ruby

$KCODE = "U"
require 'gtk2'
require 'gtksourceview'
require 'gconf2'
require 'fileutils'
require 'oniguruma'
module Oniguruma
  class ORegexp
    def _dump(_)
      self.source
    end
    def self._load(str)
      self.new(str)
    end
  end
end

require File.dirname(__FILE__) + '/../vendor/active_support'
require File.dirname(__FILE__) + '/../vendor/null'
require File.dirname(__FILE__) + '/../vendor/ruby_extensions'
require File.dirname(__FILE__) + '/../vendor/debugprinter'
require File.dirname(__FILE__) + '/../vendor/binary_enum'
require 'vendor/instruments'

require 'lib/plist'
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
require File.dirname(__FILE__) + '/syntax'
require File.dirname(__FILE__) + '/colourer'
require File.dirname(__FILE__) + '/../vendor/mdi5'
require File.dirname(__FILE__) + '/../vendor/keyword_processor'
require File.dirname(__FILE__) + '/panes'
require File.dirname(__FILE__) + '/redcar_window'
require File.dirname(__FILE__) + '/list_abstraction'

$REDCAR_ENV ||= {}
$REDCAR_ENV["test"] = false

module Redcar
  class << self
    attr_accessor :current_window, :keystrokes
        
    def startup(options={})
      options = process_params(options,
                               { :load_scripts => true,
                                 :output => :debug  })
      
      Redcar.keystrokes = Redcar::Keystrokes.new
      Redcar.window_controller = Gtk::MDI::Controller.new(RedcarWindow, :notebooks)
      Redcar.windows ||= []
      Redcar.windows << Redcar.window_controller.open_window
      Redcar.current_window = Redcar.windows.first
      Redcar.output_style = options[:output]
      if options[:load_scripts]
        Dir.glob("scripts/*.rb").sort.each do |f|
          if File.file?(f) and not f.include? "~"
            require f
          end
        end
      end
      
      Redcar.event :startup
    end
    attr_accessor :CUSTOM_DIR
    attr_accessor :ROOT_PATH
  end
end

Redcar.CUSTOM_DIR = File.expand_path(File.dirname(__FILE__) + "/../custom") 
Redcar.ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../") 
