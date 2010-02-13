module Redcar
  class EditView
    class InfoSpeedbar < Speedbar
      def self.grammar_names
        bundles  = JavaMateView::Bundle.bundles.to_a
        grammars = bundles.map {|b| b.grammars.to_a}.flatten
        items    = grammars.map {|g| g.name}.sort_by {|name| name.downcase }
      end
      
      label :time, "FOO"
      
      combo :grammar do |val|
      end
      
      def initialize(command, tab)
        @command = command
        tab_changed(tab)
      end
      
      def tab_changed(new_tab)
        @tab = new_tab
        grammar.items = InfoSpeedbar.grammar_names
        grammar.value = @tab.edit_view.grammar
        time.text = Time.now.to_s
      end
    end
    
    class InfoSpeedbarCommand < Redcar::EditTabCommand
      def execute
        @speedbar = InfoSpeedbar.new(self, tab)
        win.open_speedbar(@speedbar)
      end
    end
  end
end