
module Redcar
  class Snippets
    class TabHandler
      def self.priority
        10
      end
    
      def self.handle(edit_view, modifiers)
        controller = edit_view.document.controllers(Snippets::DocumentController).first
        if controller.in_snippet?
          if modifiers == ["Shift"]
            controller.move_backward_tab_stop
            true
          elsif modifiers == []
            controller.move_forward_tab_stop
            true
          else
            false
          end
        else
          return false if modifiers.any?
          if snippet = find_snippet(edit_view)
            doc = edit_view.document
            doc.delete(doc.cursor_offset - snippet.tab_trigger.length, snippet.tab_trigger.length)
            controller.start_snippet!(snippet)
            true
          else
            false
          end
        end
      end
      
      # Decides whether a snippet can be inserted at this location. If so
      # returns the snippet, if not returns false.
      def self.find_snippet(edit_view)
        document = edit_view.document
        @word, @offset, @start_word_offset = nil, nil, nil
        @word = word_before_cursor(edit_view)

        if @word
          @offset = document.cursor_offset
          @start_word_offset = document.cursor_offset - @word.length
          if scope_snippet = Snippets.registry.find_by_scope_and_tab_trigger(document.cursor_scope, @word)
            scope_snippet
          else
            global_options = Snippets.registry.global_with_tab(@word)
            if global_options.any?
              choose_snippet(global_options)
            end
          end
        else
          false
        end
      end
      
      def self.word_before_cursor(edit_view)
        document = edit_view.document
        line = document.get_slice(document.cursor_line_start_offset, document.cursor_offset).reverse
        if line =~ /([\S]+)(\s|$|\.)/
          word = $1.reverse
        end
        word
      end
      
      def self.choose_snippet(snippets)
        if not snippets or snippets.length == 0
          nil
        elsif snippets.length == 1
          snippets.first
        else
#          entries = snippets.map do |snippet_command|
#            [nil, snippet_command.name, fn { 
##              @buf.delete(@buf.iter(@start_word_offset), @buf.cursor_iter)
#              snippet_command.new.do
###            }]
#          end
#          Redcar::Menu.context_menu_options_popup(entries)
#          nil
          snippets.first
        end
      end

    end
  end
end
