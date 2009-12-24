
require "edit_view/command"
require "edit_view/document"
require "edit_view/document/controller"
require "edit_view/document/mirror"
require "edit_view/edit_tab"

module Redcar
  class EditView
    include Redcar::Model
    include Redcar::Observable
    
    def self.start
      Sensitivity.new(:edit_tab_focussed, Redcar.app, false, [:tab_focussed]) do |tab|
        tab and tab.is_a?(EditTab)
      end
    end
    
    attr_reader :document
    
    def initialize(tab)
      @tab = tab
      create_document
      @grammar = nil
      @focussed = nil
    end
    
    def create_document
      @document = Redcar::Document.new(self)
    end
    
    def title=(title)
      @tab.title = title
    end
    
    def cursor_offset=(offset)
      controller.cursor_offset = offset
    end
    
    def cursor_offset
      controller.cursor_offset
    end
    
    def scroll_to_line(line_index)
      controller.scroll_to_line(line_index)
    end
    
    def grammar
      @grammar
    end
    
    def grammar=(name)
      @grammar = name
      notify_listeners(:grammar_changed, name)
    end
    
    def set_grammar(name)
      @grammar = name
    end
    
    def gained_focus
      notify_listeners(:focussed)
    end
    
    def serialize
      { :contents      => document.to_s,
        :cursor_offset => cursor_offset,
        :grammar       => grammar         }
    end
    
    def deserialize(data)
      self.grammar       = data[:grammar]
      document.text      = data[:contents]
      self.cursor_offset = data[:cursor_offset]
    end
  end
end
