
module Redcar
  module Scm
    class ScmController
      include Redcar::Tree::Controller
      
      def initialize(repo)
        @repo = repo
      end
      
      def activated(tree, node)
        if node.respond_to?(:activated)
          node.activated
        end
      end
      
      def right_click(tree, node)
        menu = Menu::Builder.build do
          item("Refresh", :priority => :last) { tree.refresh }
        end
        
        Application::Dialog.popup_menu(menu, :pointer)
      end
    end
  end
end
