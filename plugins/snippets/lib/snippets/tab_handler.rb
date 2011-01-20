
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
          find_snippet(edit_view)
        end
      end

      def self.activate_snippet(edit_view, snippet)
        controller = edit_view.document.controllers(Snippets::DocumentController).first
        doc = edit_view.document
        edit_view.compound do
          doc.delete(doc.cursor_offset - snippet.tab_trigger.length, snippet.tab_trigger.length)
          controller.start_snippet!(snippet)
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
          options = find_snippet_options(document.cursor_scope, @word)
          if options.any?
            choose_snippet(edit_view, options)
          end
        end
      end

      #search for snippet matches inside a word block in an intelligent way
      def self.find_snippet_options(scope,word)
        search_word = word
        options = search_registry(scope,word)
        if not options.any? and word.match(/\W/) and word.match(/\w/)

          #most likely, there is just one symbol preceding the snippet
          if not options.any? and char = word.index(/\w/,word.index(/\W/))
            search_word   = word[char,word.split(//).length]
            options = search_registry(scope, search_word)
          end

          #otherwise, search from the end
          if not options.any?
            offset = -1
            while not options.any? and
            (offset * -1) < word.split(//).length and
            symbol_idx = word.rindex(/\W/,offset) and
            char = word.index(/\w/,symbol_idx)
              search_word   = word[char,word.split(//).length]
              options       = search_registry(scope, search_word)
              offset        = offset - 1
            end
          end
        end
        options
      end

      def self.search_registry(scope,word)
        Snippets.registry.find_by_scope_and_tab_trigger(scope,word)
      end

      def self.word_before_cursor(edit_view)
        document = edit_view.document
        line = document.get_slice(document.cursor_line_start_offset, document.cursor_offset).reverse
        if !line.empty? && !(line[0].chr =~ /\s/) && line =~ /([\S]+)(\s|$|\.)/
          word = $1.reverse
        end
        word
      end

      def self.choose_snippet(edit_view, snippets)
        if not snippets or snippets.length == 0
          false
        elsif snippets.length == 1
          activate_snippet(edit_view, snippets.first)
          true
        else
          builder = Menu::Builder.new do
            snippets.group_by {|s| s.bundle_name }.each do |_, bsnippets|
              bsnippets.each_with_index do |snippet, i|
                item(snippet.name||"<untitled>") do
                  Snippets::TabHandler.activate_snippet(edit_view, snippet)
                end
              end
              separator
            end
          end
          Redcar.app.focussed_window.popup_menu_with_numbers(builder.menu)
          true
        end
      end

    end
  end
end
