
module Redcar
  module Scm
    class ScmController
      include Redcar::Tree::Controller
      
      COMMAND_MAP = {
        :new => [:index_add, :index_ignore],
        :indexed => [:index_revert, :index_unsave],
        :deleted => [:index_restore, :index_unsave],
        :missing => [:index_restore, :index_delete],
        :changed => [:index_save, :index_revert],
        :unmerged => [:index_save, :index_delete],
        :commitable => [:commit],
      }
      
      def initialize(repo)
        @repo = repo
      end
      
      def activated(tree, node)
        if node.respond_to?(:diff)
          diff = node.diff
          if diff
            # TODO: if we can provide a text diff of ourselves, then display it
          end
        end
      end
      
      def right_click(tree, node)
        repo = @repo
        
        # TODO: In lieu of actually supporting multi-select, make it obvious
        # that we don't.
        if tree.selection.length > 1
          tree.select(node)
        end
        
        menu = Menu::Builder.build do
          if node.is_a?(Scm::ScmMirror::Change) and repo.supported_commands.include?(:index)
            # commands may end up in the array twice, but include? doesn't care
            commands = node.status.map {|s| COMMAND_MAP[s]}.flatten
            
            if (commands.include?(:commit))
              item(repo.translations[:commitable]) { Scm::Manager.open_commit_tab(repo, node) }
            end
            if (commands.include?(:index_add))
              item(repo.translations[:index_add]) { repo.index_add(node); tree.refresh }
            end
            if (commands.include?(:index_ignore))
              item(repo.translations[:index_ignore]) { repo.index_ignore(node); tree.refresh }
            end
            if (commands.include?(:index_save))
              item(repo.translations[:index_save]) { repo.index_save(node); tree.refresh }
            end
            if (commands.include?(:index_unsave))
              item(repo.translations[:index_unsave]) { repo.index_unsave(node); tree.refresh }
            end
            if (commands.include?(:index_revert))
              item(repo.translations[:index_revert]) { repo.index_revert(node); tree.refresh }
            end
            if (commands.include?(:index_restore))
              item(repo.translations[:index_restore]) { repo.index_restore(node); tree.refresh }
            end
            if (commands.include?(:index_delete))
              item(repo.translations[:index_delete]) { repo.index_delete(node); tree.refresh }
            end
            
            separator
          elsif node.is_a?(Scm::ScmMirror::ChangesNode)
            item(repo.translations[:commit]) { Scm::Manager.open_commit_tab(repo) }
            
            separator
          elsif node.is_a?(Scm::ScmMirror::CommitsNode)
            item(repo.translations[:push]) { repo.push!; tree.refresh }
            
            separator
          end
          item("Refresh", :priority => :last) { repo.refresh; tree.refresh }
        end
        
        Application::Dialog.popup_menu(menu, :pointer)
      end
    end
  end
end
