# Some Icons by Yusuke Kamiyamane.
# http://p.yusukekamiyamane.com/
#
# Licensed under a Creative Commons Attribution 3.0 license.
# http://creativecommons.org/licenses/by/3.0/
module Redcar
  module Textmate
    TREE_TITLE = "Bundles"
    class ShowSnippetTree < Redcar::Command
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
          win.treebook.focus_tree(tree)
        else
          tree = Tree.new(TreeMirror.new(Textmate.all_bundles),TreeController.new)
          win.treebook.add_tree(tree)
        end
      end
    end

    class ReloadSnippetTree < Redcar::Command
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
          win.treebook.remove_tree(tree)
          tree = Tree.new(TreeMirror.new(Textmate.all_bundles),TreeController.new)
          win.treebook.add_tree(tree)
        else
          ShowSnippetTree.new.run
        end
      end
    end

    class TreeController
      include Redcar::Tree::Controller

      def right_click(tree, node)
        controller = self
        menu = Menu.new
        Redcar.plugin_manager.objects_implementing(:bundle_context_menus).each do |object|
          case object.method(:bundle_context_menus).arity
          when 1
            menu.merge(object.bundle_context_menus(node))
          when 2
            menu.merge(object.bundle_context_menus(tree, node))
          when 3
            menu.merge(object.bundle_context_menus(tree, node, controller))
          else
            puts("Invalid bundle_context_menus hook detected in "+object.class.name)
          end
        end
        Application::Dialog.popup_menu(menu, :pointer)
      end

      def activated(tree, node)
        if node.leaf? and
            tab = Redcar.app.focussed_notebook_tab and
            tab.is_a?(EditTab)
          doc = tab.document
          if tab.edit_tab? and doc
            controller = doc.controllers(Snippets::DocumentController).first
            controller.start_snippet!(node.snippet)
            tab.focus
          end
        end
      end
    end

    class TreeMirror
      include Redcar::Tree::Mirror

      def initialize(bundles)
        @top = []
        bundles.sort_by {|bundle| (bundle.name||"").downcase}.each_with_index do |b, i|
          if b.name and b.snippets and b.snippets.size() > 0
            name = b.name.downcase
            unless Textmate.storage['select_bundles_for_tree'] and !Textmate.storage['loaded_bundles'].to_a.include?(name)
              build_tree(@top, b)
            end
          end
        end

        if @top.size() < 1
          @top = [EmptyTree.new]
        end
      end

      def build_tree(tree, bundle)
        if bundle.main_menu and bundle.main_menu["items"]
          main_menu = bundle.main_menu
          group = BundleNode.new(bundle.name)
          main_menu["items"].each do |item|
            build_tree_from_item(group.children, bundle, item)
          end
          tree << group
        end
      end

      def build_tree_from_item(tree, bundle, item)
        #if item is a snippet, add to tree
        if snippet = Textmate.uuid_hash[item] and snippet.is_a?(Textmate::Snippet)
          return unless snippet.name and snippet.name != ""
          tree << SnippetNode.new(snippet)
        #if item has submenus, make a group and add sub-items
        elsif sub_menu = bundle.sub_menus[item]
          unless sub_menu["items"].size() < 1
            group = SnippetGroup.new(sub_menu["name"])
            sub_menu["items"].each do |sub_item|
              build_tree_from_item(group.children, bundle, sub_item)
            end
            tree << group
          end
        end
      end

      def title
        TREE_TITLE
      end

      def top
        @top
      end
    end

    class EmptyTree
      include Redcar::Tree::Mirror::NodeMirror
      def text
        "No snippets found"
      end
    end

    class BundleNode
      include Redcar::Tree::Mirror::NodeMirror
      attr_writer :children

      def initialize(name)
        @children = []
        @text = name
      end

      def leaf?
        false
      end

      def text
        @text
      end

      def children
        @children
      end

      def icon
        if Textmate.storage['loaded_bundles'].include?(text.downcase)
          File.dirname(__FILE__) + "/../../icons/ui-menu-blue.png"
        else
          File.dirname(__FILE__) + "/../../icons/tree_mode.gif"
        end
      end
    end

    class SnippetGroup
      include Redcar::Tree::Mirror::NodeMirror

      attr_writer :children

      def initialize(name)
        @children = []
        @text = name
      end

      def icon
        File.dirname(__FILE__) + "/../../icons/tree_mode.gif"
      end

      def leaf?
        false
      end

      def text
        @text
      end

      def children
        @children
      end
    end

    class SnippetNode
      include Redcar::Tree::Mirror::NodeMirror

      def initialize(snippet)
        @snippet = snippet
        @name = snippet.name
        #custom menu string
        if snippet.tab_trigger
          @name << " (#{snippet.tab_trigger})"
        end
      end

      def icon
        File.dirname(__FILE__) + "/../../icons/document-snippet.png"
      end

      def text
        @name
      end

      def leaf?
        true
      end

      def children
        []
      end

      def snippet
        @snippet
      end
    end
  end
end
