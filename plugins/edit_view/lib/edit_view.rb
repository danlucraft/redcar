
require "edit_view/command"
require "edit_view/document"
require "edit_view/document/command"
require "edit_view/document/controller"
require "edit_view/document/mirror"
require "edit_view/edit_tab"
require "edit_view/tab_settings"
require "edit_view/info_speedbar"

module Redcar
  class EditView
    include Redcar::Model
    extend Redcar::Observable
    include Redcar::Observable
    
    extend Forwardable

    module Handler
      include Interface::Abstract

      def handle(edit_view, modifiers)
      end
    end
    
    class << self
      attr_reader :undo_sensitivity, :redo_sensitivity
      attr_reader :focussed_edit_view
    end
    
    def self.tab_settings
      @tab_settings ||= TabSettings.new
    end
      
    def self.storage
      @storage ||= Plugin::Storage.new('edit_view_plugin')
    end

    def self.all_handlers(type)
      result = []
      Redcar.plugin_manager.loaded_plugins.each do |plugin|
        if plugin.object.respond_to?(:"#{type}_handlers")
          result += plugin.object.send(:"#{type}_handlers")
        end
      end
      result.each {|h| Handler.verify_interface!(h) }
    end

    def self.all_tab_handlers
      all_handlers(:tab)
    end
    
    def self.all_esc_handlers
      all_handlers(:esc)
    end

    def self.all_arrow_left_handlers
      all_handlers(:arrow_left)
    end

    def self.all_arrow_right_handlers
      all_handlers(:arrow_right)
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
        default_font_size = 9
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
    
    def self.focussed_tab_edit_view
      Redcar.app.focussed_notebook_tab.edit_view if Redcar.app.focussed_notebook_tab and Redcar.app.focussed_notebook_tab.edit_tab?
    end
    
    def self.focussed_edit_view_document
      focussed_tab_edit_view.document if focussed_tab_edit_view
    end
    
    def self.focussed_document_mirror
      focussed_edit_view_document.mirror if focussed_edit_view_document
    end
    
    attr_reader :document
    
    def initialize
      create_document
      @grammar = nil
      @focussed = nil
      self.tab_width = EditView.tab_settings.width_for(grammar)
      self.soft_tabs = EditView.tab_settings.softness_for(grammar)
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
      self.tab_width = EditView.tab_settings.width_for(name) || tab_width
    end
    
    def focus
      notify_listeners(:focussed)
    end

    def tab_width
      @tab_width
    end
    
    def tab_width=(val)
      @tab_width = val
      EditView.tab_settings.set_width_for(grammar, val)
      notify_listeners(:tab_width_changed, val)
    end
    
    def set_tab_width(val)
      @tab_width = val
    end
    
    def soft_tabs?
      @soft_tabs
    end
    
    def soft_tabs=(bool)
      @soft_tabs = bool
      EditView.tab_settings.set_softness_for(grammar, bool)
      notify_listeners(:softness_changed, bool)
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
    
    def tab_pressed(modifiers)
      EditView.all_tab_handlers.detect { |h| h.handle(self, modifiers) }
    end
    
    def esc_pressed(modifiers)
      EditView.all_esc_handlers.detect { |h| h.handle(self, modifiers) }
    end
    
    def left_pressed(modifiers)
      EditView.all_arrow_left_handlers.detect { |h| h.handle(self, modifiers) }
    end
    
    def right_pressed(modifiers)
      EditView.all_arrow_right_handlers.detect { |h| h.handle(self, modifiers) }
    end
    
    def self.tab_handlers
      [IndentTabHandler]
    end
    
    class IndentTabHandler
      def self.handle(edit_view, modifiers)
        return false if modifiers.any?
        doc = edit_view.document
        if edit_view.soft_tabs?
          line = doc.get_line(doc.cursor_line)
          width = edit_view.tab_width
          imaginary_cursor_offset = ArrowHandler.real_offset_to_imaginary(line, width, doc.cursor_line_offset)
          next_tab_stop_offset = (imaginary_cursor_offset/width + 1)*width
          insert_string = " "*(next_tab_stop_offset - imaginary_cursor_offset)
          doc.insert(doc.cursor_offset, insert_string)
          doc.cursor_offset = doc.cursor_offset + insert_string.length
        else
          doc.insert(doc.cursor_offset, "\t")
          doc.cursor_offset += 1
        end
        true
      end
    end
    
    def self.arrow_left_handlers
      [ArrowLeftHandler]
    end
    
    class ArrowHandler
      def self.real_offset_to_imaginary(line, width, offset)
        before = line[0...offset]
        before.length + (width - 1)*before.scan("\t").length
      end

      def self.imaginary_offset_to_real(line, width, offset)
        real_ix = 0
        imaginary_ix = 0
        prev_real_ix = 0
        prev_imaginary_ix = 0
        sc = StringScanner.new(line)
        while sc.skip(/[^\t]*\t/)
          prev_real_ix = real_ix
          prev_imaginary_ix = imaginary_ix
          imaginary_ix += sc.pos - real_ix + width - 1
          real_ix = sc.pos
          p(:prev_real => prev_real_ix, :prev_imaginary => prev_imaginary_ix, :real => real_ix, :imag => imaginary_ix)
          if imaginary_ix > offset
            return prev_real_ix + (offset - prev_imaginary_ix)
          elsif imaginary_ix == offset
            return real_ix
          end
        end
        real_ix + offset - imaginary_ix
      end
    end
    
    class ArrowLeftHandler < ArrowHandler
      def self.handle(edit_view, modifiers)
        return false if modifiers.any?
        doc = edit_view.document
        if edit_view.soft_tabs?
          line = doc.get_line(doc.cursor_line)
          width = edit_view.tab_width
          return if doc.cursor_line_offset == 0
          imaginary_cursor_offset = real_offset_to_imaginary(line, width, doc.cursor_line_offset)
          if imaginary_cursor_offset % width == 0
            tab_stop = imaginary_cursor_offset/width - 1
          else
            tab_stop = imaginary_cursor_offset/width
          end
          tab_stop_offset = tab_stop*width
          next_tab_stop_offset = tab_stop_offset + width
          if line.length >= imaginary_offset_to_real(line, width, next_tab_stop_offset)
            before_line = line[imaginary_offset_to_real(line, width, tab_stop_offset)...doc.cursor_line_offset]
            if match = before_line.match(/\s+$/)
              doc.cursor_offset = doc.cursor_offset - match[0].length
            else
              default(doc)
            end
          else
            default(doc)
          end
        else
          default(doc)
        end
      end
      
      def self.default(doc)
        doc.cursor_offset = doc.cursor_offset - 1
      end
      
    end
        
    def self.arrow_right_handlers
      [ArrowRightHandler]
    end
    
    class ArrowRightHandler < ArrowHandler
      def self.handle(edit_view, modifiers)
        return false if modifiers.any?
        doc = edit_view.document
        if edit_view.soft_tabs?
          line = doc.get_line(doc.cursor_line)
          width = edit_view.tab_width
          imaginary_cursor_offset = real_offset_to_imaginary(line, width, doc.cursor_line_offset)
          tab_stop = imaginary_cursor_offset/width + 1
          tab_stop_offset = tab_stop*width
          if line.length >= imaginary_offset_to_real(line, width, tab_stop_offset)
            after_line = line[doc.cursor_line_offset...imaginary_offset_to_real(line, width, tab_stop_offset)]
            if match = after_line.match(/^\s+/)
              doc.cursor_offset = doc.cursor_offset + match[0].length
            else
              default(doc)
            end
          else
            default(doc)
          end
        else
          default(doc)
        end
      end
      
      def self.default(doc)
        doc.cursor_offset = doc.cursor_offset + 1
      end
    end
  end
end

