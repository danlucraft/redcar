
module Redcar
  module Scm
    class ScmChangesController
      include Redcar::Tree::Controller
      
      COMMAND_MAP = {
        :new => [:index_add, :index_ignore, :index_ignore_all, :index_delete],
        :indexed => [:index_revert, :index_unsave],
        :deleted => [:index_unsave, :index_restore],
        :missing => [:index_delete, :index_restore],
        :changed => [:index_save, :index_revert],
        :unmerged => [:index_save, :index_delete],
        :commitable => [:commit],
        :moved => [:index_unsave],
      }
      
      def initialize(repo)
        @repo = repo
      end
      
      def activated(tree, node)
        if node.respond_to?(:status) and node.status == [:unmerged]
          Project::FileCreateCommitCommand.new(node.path).run
        elsif node.respond_to?(:diff)
          diff = node.diff
          if diff
            tab = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
            edit_view = tab.edit_view  
            mirror = Scm::DiffMirror.new(node, diff)
            edit_view.document.mirror = mirror
            edit_view.grammar = "Diff"
            tab.focus
          end
        end
      end
      
      def drag_controller(tree)
        DragController.new(tree, @repo)
      end
      
      def right_click(tree, node)
        repo = @repo
        
        # TODO: In lieu of actually supporting multi-select, make it obvious
        # that we don't.
        if tree.selection.length > 1
          tree.select(node)
        end
        
        menu = Menu::Builder.build do
          if node.is_a?(Scm::ScmChangesMirror::Change) and repo.supported_commands.include?(:index)
            # commands may end up in the array twice, but include? doesn't care
            commands = node.status.map {|s| COMMAND_MAP[s]}.flatten
            file_extension = File.extname(node.path)
            if file_extension.length > 0
              file_extension = file_extension[1, file_extension.length-1]
            else
              file_extension = nil
            end
            
            if (commands.include?(:commit))
              item(repo.translations[:commitable]) { Scm::Manager.open_commit_tab(repo, node) }
            end
            if (commands.include?(:index_add))
              item(repo.translations[:index_add]) { if repo.index_add(node); tree.refresh; end }
            end
            if (commands.include?(:index_ignore))
              item(repo.translations[:index_ignore]) { if repo.index_ignore(node); tree.refresh; end }
            end
            if (file_extension and commands.include?(:index_ignore_all))
              item(repo.translations[:index_ignore_all] % file_extension) { 
                if repo.index_ignore_all(file_extension, node)
                  tree.refresh
                end
              }
            end
            if (commands.include?(:index_save))
              item(repo.translations[:index_save]) { if repo.index_save(node); tree.refresh; end }
            end
            if (commands.include?(:index_unsave))
              item(repo.translations[:index_unsave]) { if repo.index_unsave(node); tree.refresh; end }
            end
            if (commands.include?(:index_delete))
              item(repo.translations[:index_delete]) { if repo.index_delete(node); tree.refresh; end }
            end
            if (commands.include?(:index_revert))
              item(repo.translations[:index_revert]) { if repo.index_revert(node); tree.refresh; end }
            end
            if (commands.include?(:index_restore))
              item(repo.translations[:index_restore]) { if repo.index_restore(node); tree.refresh; end }
            end
            
            separator
          elsif node.is_a?(Scm::ScmChangesMirror::ChangesNode) and node.change_types != :unindexed
            item(repo.translations[:commit]) { Scm::Manager.open_commit_tab(repo) }
            
            separator
          end
          item("Refresh", :priority => :last) { repo.refresh; tree.refresh }
        end
        
        Application::Dialog.popup_menu(menu, :pointer)
      end
    end
  end
end
