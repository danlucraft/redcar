
require "edit_view/command"
require "edit_view/document"
require "edit_view/document/controller"
require "edit_view/document/mirror"
require "edit_view/edit_tab"

module Redcar
  class EditView
    include Redcar::Model
    include Redcar::Observable
    
    extend Forwardable

    class << self
      attr_reader :undo_sensitivity, :redo_sensitivity
    end
    
    def self.start
      Sensitivity.new(:edit_tab_focussed, Redcar.app, false, [:tab_focussed]) do |tab|
        tab and tab.is_a?(EditTab)
      end
      Sensitivity.new(:selected_text, Redcar.app, false, [:focussed_tab_selection_changed, :tab_focussed]) do
        if win = Redcar.app.focussed_window
          tab = win.focussed_notebook.focussed_tab
          tab and tab.is_a?(EditTab) and tab.edit_view.document.selection?
        end
      end
      @undo_sensitivity = 
        Sensitivity.new(:undoable, Redcar.app, false, [:focussed_tab_changed, :tab_focussed]) do
          tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
          tab and tab.is_a?(EditTab) and tab.edit_view.undoable?
        end
      @redo_sensitivity = 
        Sensitivity.new(:redoable, Redcar.app, false, [:focussed_tab_changed, :tab_focussed]) do
          tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
          tab and tab.is_a?(EditTab) and tab.edit_view.redoable?
        end
      Sensitivity.new(:clipboard_not_empty, Redcar.app, false, [:clipboard_added]) do
        Redcar.app.clipboard.length > 0
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
    
    def_delegators :controller, :undo,      :redo,
                                :undoable?, :redoable?,
                                :reset_undo,
                                :cursor_offset, :cursor_offset=,
                                :scroll_to_line
    
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
