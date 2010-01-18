
module Redcar
  class ApplicationSWT
    class HtmlTab < Tab
      attr_reader :browser
      
      def initialize(model, notebook)
        super
        @model.add_listener(:changed_title) { |title| @item.text = title }
      end
      
      def create_tab_widget
        @browser = Swt::Browser.new(notebook.tab_folder, Swt::SWT::NONE)
        @widget = @browser
        @item.control = @widget
      end
      
      # Focuses the Browser tab within the CTabFolder, and gives the keyboard
      # focus to the EditViewSWT.
      def focus
        super
        browser.set_focus
      end
      
      # Close the HtmlTab, disposing of any resources along the way.
      def close
        @browser.dispose
        super
      end
    end
  end
end