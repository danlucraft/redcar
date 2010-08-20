
module Redcar
  module Scm
    class ScmCommitsController
      include Redcar::Tree::Controller
      
      def initialize(repo)
        @repo = repo
      end
      
      def activated(tree, node)
        if node.respond_to?(:log)
          log = node.log
          if log
            # TODO: if we can provide a text log of ourselves, then display it
          end
        end
      end
      
      def right_click(tree, node)
        repo = @repo
        
        # In lieu of actually supporting multi-select, make it obvious
        # that we don't.
        if tree.selection.length > 1
          tree.select(node)
        end
        
        menu = Menu::Builder.build do
          if node.is_a?(Scm::ScmCommitsMirror::CommitsNode)
            item(repo.translations[:push]) { 
              if node.branch
                refresh = node.repo.push! node.branch
              else
                refresh = node.repo.push!
              end
              tree.refresh if refresh
            }
            
            separator
          end
          item("Refresh", :priority => :last) { repo.refresh; tree.refresh }
        end
        
        Application::Dialog.popup_menu(menu, :pointer)
      end
    end
  end
end
