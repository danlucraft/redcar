
module Redcar
  class Snippets
    class TabHandler
      def self.priority
        10
      end
    
      def self.handle(edit_view, modifiers)
        return false if modifiers.any?
        controller = edit_view.document.controllers(Snippets::DocumentController).first
        if controller.in_snippet?
          controller.move_forward_tab_stop
          true
        else
          if snippet = find_snippet(edit_view)
            p [:found_snippet, snippet]
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
          if snippet = choose_snippet(Snippets.registry.global_with_tab(@word))
            snippet
#          elsif snippets_for_scope = SnippetInserter.snippets_for_scope(@buf.cursor_scope) and
#              snippet = choose_snippet(snippets_for_scope[@word])
#            snippet
          else
            false
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
