
module Redcar
  module Textmate

    class ShowSnippetTree < Redcar::Command
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
          win.treebook.focus_tree(tree)
        else
          tree = Tree.new(TreeMirror.new,TreeController.new)
          win.treebook.add_tree(tree)
        end
      end
    end

    class ReloadSnippetTree < Redcar::Command
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
          win.treebook.remove_tree(tree)
          tree = Tree.new(TreeMirror.new,TreeController.new)
          win.treebook.add_tree(tree)
        else
          ShowSnippetTree.new.run
        end
      end
    end

    class CreateNewSnippet < Redcar::Command
      def initialize bundle,menu=nil
        @bundle,@menu = bundle,menu
      end

      def execute
        result = Redcar::Application::Dialog.input("Create Snippet","Choose a name for your new snippet:")
        if result[:button] == :ok and not result[:value].empty?
          BundleEditor.create_snippet result[:value], @bundle, @menu
        end
      end
    end

    class OpenSnippetEditor < Redcar::Command
      def initialize snippet, bundle=nil,menu=nil
        @snippet = snippet
        @bundle, @menu = bundle, menu
     end

      def execute
        tab = Redcar.app.focussed_window.new_tab(Redcar::HtmlTab)
        tab.html_view.controller = Textmate::SnippetEditorController.new(@snippet,tab,@bundle,@menu)
        tab.icon = :edit_code
        tab.focus
      end
    end

    class OpenBundleEditor < Redcar::Command
      def initialize bundle
        @bundle = bundle
      end

      def execute
        tab = Redcar.app.focussed_window.new_tab(Redcar::HtmlTab)
        tab.html_view.controller = Textmate::BundleEditorController.new(@bundle,tab)
        tab.icon = :edit_code
        tab.focus
      end
    end

    class CreateNewBundle < Redcar::Command
      def execute
        result = Redcar::Application::Dialog.input("Create Bundle","Choose a name for your new Bundle:")
        if result[:button] == :ok and not result[:value].empty?
          bundle_dir = File.join(Redcar.user_dir,"Bundles")
          BundleEditor.create_bundle result[:value], bundle_dir
        end
      end
    end

    class CreateNewSnippetGroup < Redcar::Command
      def initialize tree,node
        @tree, @node = tree, node
      end

      def execute
        target_uuid = @node.is_a?(BundleNode) ? nil : @node.uuid
        group_uuid  = BundleEditor.create_submenu "New Menu", @node.bundle, target_uuid
        bundle_node = @tree.tree_mirror.bundle_node_by_name(@node.bundle.name)
        if new_group = bundle_node.child_by_uuid(group_uuid)
          @node = bundle_node.child_by_uuid target_uuid
          @tree.expand(@node)
          @tree.edit(new_group)
          @node = bundle_node.child_by_uuid target_uuid
          @tree.expand(@node)
          @tree.select(new_group)
        end
      end
    end

    class RenameSnippetGroup < Redcar::Command
      def initialize tree, node
        @tree, @node = tree, node
      end

      def execute
        @tree.edit(@node)
      end
    end

    class SortNodes < Redcar::Command
      def initialize tree,node
        @tree, @node = tree, node
      end

      def execute
        @node.children = @node.children.sort_by do |n|
          n.text.downcase
        end.sort_by do |n|
          n.is_a?(SnippetGroup) ? 0 : 1
        end
        uuids = @node.children.map {|n| n.uuid}
        @node.menu = @node.menu.sort_by{|id| uuids.index(id)}
        BundleEditor.write_bundle(@node.bundle)
        BundleEditor.reload_cache
        @tree.refresh
      end
    end

    class DeleteNode < Redcar::Command
      def initialize node
        @node = node
      end

      def execute
        if @node.is_a? SnippetGroup and @node.children.size == 0
          process_deletion
        else
          result = Redcar::Application::Dialog.message_box(
            "Delete "+@node.text+" (and all children)?",{:buttons => :yes_no})
          if result == :yes
            process_deletion
          end
        end
      end

      def process_deletion
          delete(@node)
          BundleEditor.write_bundle(@node.bundle)
          BundleEditor.refresh_trees([@node.bundle.name])
          BundleEditor.reload_cache
      end

      def delete node
        # node.children.each {|c| delete(c)} if node.children
        uuid = node.parent.is_a?(SnippetGroup) ? node.parent.uuid : nil
        case node
        when SnippetNode
          BundleEditor.delete_snippet(node.bundle,node.snippet, uuid)
        when SnippetGroup
          BundleEditor.delete_submenu(node.bundle,node.uuid, uuid)
        end
      end
    end

    class ClearBundleMenu < Redcar::Command
      def execute
        Textmate.storage['loaded_bundles'] = []
        Textmate.refresh_tree
        Redcar.app.refresh_menu!
      end
    end

    class RemovePinnedBundle < Redcar::Command
      def initialize(bundle_name)
        @bundle_name = bundle_name.downcase
      end

      def execute
        unless not Textmate.storage['loaded_bundles'].include?(@bundle_name)
          bundles = Textmate.storage['loaded_bundles'] || []
          bundles.delete(@bundle_name)
          Textmate.storage['loaded_bundles'] = bundles
          Textmate.refresh_tree
          Redcar.app.refresh_menu!
        end
      end
    end

    class PinBundleToMenu < Redcar::Command
      def initialize(bundle_name)
        @bundle_name = bundle_name.downcase
      end

      def execute
        unless Textmate.storage['loaded_bundles'].include?(@bundle_name)
          bundles = Textmate.storage['loaded_bundles'] || []
          bundles << @bundle_name
          Textmate.storage['loaded_bundles'] = bundles
          Textmate.refresh_tree
          Redcar.app.refresh_menu!
        end
      end
    end
  end
end
