
module Redcar
  module Scm
    class ScmController
      include Redcar::Tree::Controller
      
      def activated(tree, node)
        if node.respond_to?(:activated)
          node.activated
        end
      end
      
      def right_click(tree, node)
        menu = Menu::Builder.build do
          item("Refresh", :priority => :first) { tree.refresh }
        end
        
        if node.respond_to?(:right_click)
          menu.merge(node.right_click)
        end
        
        Application::Dialog.popup_menu(menu, :pointer)
      end
    end
  end
end
