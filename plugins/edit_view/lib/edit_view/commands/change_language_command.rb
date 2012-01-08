module Redcar
  class EditView

    class ChangeLanguageCommand < Redcar::EditTabCommand

      class ChangeLanguageDialog < FilterListDialog
        def initialize(tab)
          @tab = tab
          super()
        end
        
        def update_list(filter)
          bundles  = JavaMateView::Bundle.bundles.to_a
          grammars = bundles.map {|b| b.grammars.to_a}.flatten
          names    = grammars.map {|g| g.name}.sort_by {|name| name.downcase }
          filter_and_rank_by(names, filter)
        end
  
        def selected(name, ix)
          @tab.edit_view.grammar = name
          close
        end
      end

      def execute
        ChangeLanguageDialog.new(tab).open
      end
    end
    
  end
end