module Redcar
  class Snippets
    class Explorer < FilterListDialog
      def initialize(document)
        @document = document
        super()
      end
      
      def update_list(query)
        return [] if query == ""
        matching_snippets = filter_and_rank_by(all_snippets, query, 1000) do |s| 
          display(s)
        end
        current_scope = Redcar.update_gui { @document.cursor_scope }
        @last_list = matching_snippets.select do |snippet|
          if snippet.scope
            !!JavaMateView::ScopeMatcher.get_match(snippet.scope, current_scope)
          else
            true
          end
        end
        @last_list.map {|s| display(s) }
      end
      
      def selected(_, ix)
        if @last_list
          close
          insert_snippet(@last_list[ix])
        end
      end
      
      private
      
      def display(snippet)
        "#{snippet.bundle_name} / #{snippet.name} (#{snippet.tab_trigger}↦)"
      end
      
      def all_snippets
        Snippets.registry.snippets
      end
      
      def insert_snippet(snippet)
        controller = @document.controllers(Snippets::DocumentController).first
        controller.start_snippet!(snippet)
      end
    end
  end
end
