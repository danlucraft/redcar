module Redcar
  class ApplicationSWT
    class Notebook
      def initialize(model, tab_folder)
        model.controller = self
      end
    end
  end
end
