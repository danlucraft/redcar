
require 'auto_completer/current_document_completion_source'
require 'auto_completer/document_controller'
require 'auto_completer/word_iterator'
require 'auto_completer/word_list'
require 'auto_completer/list_dialog'

module Redcar
  class AutoCompleter
    WORD_CHARACTERS = /\w|_/ # /(\s|\t|\.|\r|\(|\)|,|;)/

    def self.document_controller_types
      [AutoCompleter::DocumentController]
    end

    def self.autocompletion_source_types
      [AutoCompleter::CurrentDocumentCompletionSource]
    end

    def self.all_autocompletion_source_types
      result = []
      Redcar.plugin_manager.objects_implementing(:autocompletion_source_types).each do |object|
        result += object.autocompletion_source_types
      end
      result
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          group(:priority => 83) do
            item "Auto Complete",          AutoCompleter::AutoCompleteCommand
            item "Menu Auto Complete",     AutoCompleter::MenuAutoCompleterCommand
          end
        end
      end
    end

    class AutoCompleteCommand < Redcar::EditTabCommand

      def execute
        controller = doc.controllers(AutoCompleter::DocumentController).first
        controller.start_modification

        if controller.in_completion?
          doc.delete(doc.cursor_offset - controller.length_of_previous, controller.length_of_previous)
          prefix = controller.prefix
          left = controller.left
          right = controller.right
          word_list = controller.word_list
        else
          prefix, left, right = touched_prefix
          if prefix
            word_list = alternatives(prefix)
            controller.word_list = word_list
            controller.prefix    = prefix
            controller.left      = left
            controller.right     = right
          end
        end

        if prefix
          index = (controller.index || 0) + 1
          if word_list.completions.length == index
            index = 0
          end
          completion = word_list.completions[index]
          controller.index = index

          start_offset = right
          doc.insert(right, completion[prefix.length..-1])
          word_end_offset = right + completion.length - prefix.length
          doc.cursor_offset = word_end_offset

          controller.length_of_previous = completion.length - prefix.length

          controller.start_completion
        end
        controller.end_modification
      end

      private

      def alternatives(prefix)
        sources = AutoCompleter.all_autocompletion_source_types.map do |t|
          t.new(doc, Project::Manager.focussed_project)
        end
        word_list = WordList.new
        sources.each do |source|
          if alts = source.alternatives(prefix)
            word_list.merge!(alts)
          end
        end
        word_list
      end

      # returns the prefix that is being touched by the cursor and a range
      # containing offsets of the prefix.
      def touched_prefix
        range = doc.current_word_range
        left, right = range.first, doc.cursor_offset
        prefix = doc.get_range(left, right - left)
        return nil if prefix.length == 0
        return prefix, left, right
      end
    end

    class MenuAutoCompleterCommand < AutoCompleteCommand

      def execute
        controller = doc.controllers(AutoCompleter::DocumentController).first
        input_word = ""
        word_list  = controller.word_list
        prefix, left, right = touched_prefix
        if prefix
          word_list = alternatives(prefix)
          cur_doc   = doc
          key_list  = word_list.words.keys
          height    = [key_list.size,8].min
          dialog    = ListDialog.new(prefix,cur_doc)
          dialog.update_list(key_list)
          dialog.set_location(cur_doc.cursor_offset - prefix.length)
          dialog.set_size 300, height
          dialog.open
        end
      end
    end
  end
end
