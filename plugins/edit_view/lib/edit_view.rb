
require "edit_view/command"
require "edit_view/document"
require "edit_view/document/command"
require "edit_view/document/controller"
require "edit_view/document/mirror"
require "edit_view/edit_tab"
require "edit_view/tab_widths"

module Redcar
  class EditView
    include Redcar::Model
    extend Redcar::Observable
    include Redcar::Observable
    
    extend Forwardable

    module Handler
      include Interface::Abstract

      def handle(edit_view)
      end
    end
    
    class << self
      attr_reader :undo_sensitivity, :redo_sensitivity
      attr_reader :focussed_edit_view
    end
    
    def self.tab_widths
      @tab_widths ||= TabWidths.new
    end
      
    def self.storage
      @storage ||= Plugin::Storage.new('edit_view_plugin')
    end

    def self.all_tab_handlers
      result = []
      Redcar.plugin_manager.loaded_plugins.each do |plugin|
        if plugin.object.respond_to?(:tab_handlers)
          result += plugin.object.tab_handlers
        end
      end
      result.each {|h| Handler.verify_interface!(h) }
    end
    
    def self.esc_handlers
      @esc_handlers ||= []
    end
    
    # Called by the GUI whenever an EditView is focussed or
    # loses focus. Sends :focussed_edit_view event.
    def self.focussed_edit_view=(edit_view)
      @focussed_edit_view = edit_view
      notify_listeners(:focussed_edit_view, edit_view)
    end
    
    def self.sensitivities
      [
        Sensitivity.new(:edit_tab_focussed, Redcar.app, false, [:tab_focussed]) do |tab|
          tab and tab.is_a?(EditTab)
        end,
        Sensitivity.new(:edit_view_focussed, EditView, false, [:focussed_edit_view]) do |edit_view|
          edit_view
        end,
        Sensitivity.new(:selected_text, Redcar.app, false, [:focussed_tab_selection_changed, :tab_focussed]) do
          if win = Redcar.app.focussed_window
            tab = win.focussed_notebook.focussed_tab
            tab and tab.is_a?(EditTab) and tab.edit_view.document.selection?
          end
        end,
        @undo_sensitivity = 
          Sensitivity.new(:undoable, Redcar.app, false, [:focussed_tab_changed, :tab_focussed]) do
            tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
            tab and tab.is_a?(EditTab) and tab.edit_view.undoable?
          end,
        @redo_sensitivity = 
          Sensitivity.new(:redoable, Redcar.app, false, [:focussed_tab_changed, :tab_focussed]) do
            tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
            tab and tab.is_a?(EditTab) and tab.edit_view.redoable?
          end,
        Sensitivity.new(:clipboard_not_empty, Redcar.app, false, [:clipboard_added, :focussed_window]) do
          Redcar.app.clipboard.length > 0
        end
      ]
    end

    def self.font_info
      if Redcar.platform == :osx
        default_font = "Monaco"
        default_font_size = 15
      elsif Redcar.platform == :linux
        default_font = "Monospace"
        default_font_size = 11
      elsif Redcar.platform == :windows
        default_font = "Courier New"
        default_font_size = 15
      end
      [ ARGV.option("font") || default_font, 
        (ARGV.option("font-size") || default_font_size).to_i ]
    end
    
    def self.font
      font_info[0]
    end
    
    def self.font_size
      font_info[1]
    end
    
    def self.theme
      ARGV.option("theme") || "Twilight"
    end    

    attr_reader :document
    
    def initialize
      create_document
      @grammar = nil
      @focussed = nil
      self.tab_width = EditView.tab_widths.for(grammar)
    end
    
    def create_document
      @document = Redcar::Document.new(self)
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
      set_grammar(name)
      notify_listeners(:grammar_changed, name)
    end
    
    def set_grammar(name)
      @grammar = name
      self.tab_width = EditView.tab_widths.for(name) || tab_width
    end
    
    def focus
      notify_listeners(:focussed)
    end

    def tab_width
      @tab_width
    end
    
    def tab_width=(val)
      @tab_width = val
      EditView.tab_widths.set_for(grammar, val)
      notify_listeners(:tab_width_changed, val)
    end
    
    def set_tab_width(val)
      @tab_width = val
    end

    def title=(title)
      notify_listeners(:title_changed, title)
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
    
    def tab_pressed
      p :tab_pressed
      doit = !EditView.all_tab_handlers.detect { |h| h.handle(self) }
    end
    
    def esc_pressed
      p :esc_pressed
      doit = true
      doit
    end
  end
end
