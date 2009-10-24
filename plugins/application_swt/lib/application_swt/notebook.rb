module Redcar
  class ApplicationSWT
    class Notebook
      attr_reader :tab_folder
      
      def initialize(model, tab_folder)
        @model, @tab_folder = model, tab_folder
        @model.controller = self
        attach_model_listeners
        attach_view_listeners
      end
      
      def attach_model_listeners
        @model.add_listener(:tab_added) do |tab|
          tab.controller = Redcar.gui.controller_for(tab).new(tab, self)
        end
      end
      
      def attach_view_listeners
        p(@tab_folder.methods.sort - Object.new.methods)
        @tab_folder.add_ctab_folder_listener do |event|
          tab = @model.tabs.detect {|tab| tab.controller.item == event.item }
          @model.remove_tab!(tab)
        end
      end
      
      def focussed_tab
        focussed_tab_item = tab_folder.get_selection
        @model.tabs.detect {|tab| tab.controller.item == focussed_tab_item}
      end
    end
  end
end
