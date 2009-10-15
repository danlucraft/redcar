module Redcar
  class ApplicationSWT
    class Notebook
      def initialize(model, tab_folder)
        @model, @tab_folder = model, tab_folder
        @model.controller = self
        attach_listeners
      end
      
      def attach_listeners
        @model.add_listener(:tab_added) do |tab|
          tab_item = Swt::Custom::CTabItem.new(@tab_folder, Swt::SWT::CLOSE)
          tab_item.text = "Hello!"
          text = Swt::Widgets::Text.new(@tab_folder, Swt::SWT::MULTI)
          text.text = "Big Text"
          tab_item.control = text
        end
      end
    end
  end
end
