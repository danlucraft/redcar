module Redcar
  class ApplicationSWT
    class Notebook
      attr_reader :tab_folder
      
      def initialize(model, tab_folder)
        @model, @tab_folder = model, tab_folder
        @model.controller = self
        attach_listeners
      end
      
      def attach_listeners
        @model.add_listener(:tab_added) do |tab|
          tab.controller = ApplicationSWT::Tab.new(tab, self)
        end
      end
    end
  end
end
