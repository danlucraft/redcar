
module Redcar
  class Toolbar
    class Main
      def self.toolbar_widget=(gtk_toolbar)
        @@gtk_toolbar = gtk_toolbar
      end
      
      def self.toolbar_widget
        @@gtk_toolbar
      end
      
      def self.append(icon, text, tooltip, options={}, &block)
        tb = @@gtk_toolbar.append(Redcar::Icon.get(icon), tooltip) do
          block.call(Redcar.current_pane, Redcar.current_tab)
        end
        if options[:sensitize_to]
          tb.sensitize_to options[:sensitize_to]
        end
      end
      
      def self.separator
        @@gtk_toolbar.append_space
      end
    end
  end
end

module Redcar
  def self.MainToolbar
    Redcar::Toolbar::Main
  end
end
