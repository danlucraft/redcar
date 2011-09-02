
module Redcar
  module Textmate
    # A test for leaks
    #class RefreshMenuTenTimes < Redcar::Command
    #  def execute
    #    puts "Refreshing menu ten times."
    #    10.times do
    #  	  Redcar.app.refresh_menu!
    #      puts "Refreshing the menu!"
    #    end
    #  end
    #end

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

      def generate_path(dir, filename, index=nil)
        File.expand_path(File.join(dir,"#{filename}#{index ? index : ''}.plist"))
      end

      def execute
        result = Redcar::Application::Dialog.input("Create Snippet","Choose a name for your new snippet:")
        if result[:button] == :ok and not result[:value].empty?
          snippet_dir = File.expand_path(File.join(@bundle.path,"Snippets"))
          FileUtils.mkdir(snippet_dir) unless File.exists?(snippet_dir)
          name = result[:value]
          filename = name.gsub(/[^a-zA-Z0-9]/,"_")
          path = generate_path(snippet_dir,filename)
          index = 0
          while File.exists?(path)
            path = generate_path(snippet_dir, filename, index+=1)
          end
          plist = {
            "name" => name,
            "uuid" => BundleEditor.generate_id,
            "tabTrigger" => "",
            "scope" => "",
            "content" => ""
          }
          xml = Redcar::Plist.plist_to_xml(plist)
          temp = Java::JavaIo::File.create_temp_file(name,'.plist')
          fake_path = temp.absolute_path
          File.open(fake_path,'w') do |f|
            f.puts(xml)
          end
          snippet = Textmate::Snippet.new(fake_path,@bundle.name)
          snippet.path = path
          temp.delete
          OpenSnippetEditor.new(snippet,@bundle,@menu).run
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
          plist = {
            "name" => result[:value],
            "contactName" => "",
            "contactEmailRot13" => "",
            "description" => "",
            "mainMenu" => {
              'items' => [],
              "submenus" => {}
            },
            "ordering" => [],
            "uuid" => BundleEditor.generate_id
          }
          bundle_dir = File.join(Redcar.user_dir,"Bundles")
          path = File.expand_path(File.join(bundle_dir,result[:value]))
          path += ".tmbundle" unless path =~ /\.tmbundle$/
          if File.exists?(path)
            Redcar::Application::Dialog.message_box("A Bundle by that name already exists.")
            return
          end
          FileUtils.mkdir(bundle_dir) unless File.exists?(bundle_dir)
          FileUtils.mkdir(path)
          xml = Redcar::Plist.plist_to_xml(plist)
          fake_path = File.join(Java::JavaLang::System.getProperty("java.io.tmpdir"),'info.plist')
          File.open(fake_path,'w') do |f|
            f.puts(xml)
          end
          bundle = Bundle.new(File.dirname(fake_path))
          bundle.path = path
          File.delete(fake_path)
          OpenBundleEditor.new(bundle).run
        end
      end
    end

    class CreateNewSnippetGroup < Redcar::Command
      def initialize bundle,menu=nil
        @bundle, @menu = bundle, menu
      end

      def execute
        result = Redcar::Application::Dialog.input("Create Snippet Menu","Choose a name for your new snippet menu:")
        if result[:button] == :ok and not result[:value].empty?
          @bundle.sub_menus = {} unless @bundle.sub_menus
          uuid = BundleEditor.generate_id
          @bundle.sub_menus[uuid] = {
            "name"  => result[:value],
            "items" => []
          }
          if @menu and @bundle.sub_menus[@menu]
            @bundle.sub_menus[@menu]['items'] << uuid
          else
            @bundle.main_menu = {} unless @bundle.main_menu
            @bundle.main_menu['items'] = [] unless @bundle.main_menu['items']
            @bundle.main_menu['items'] << uuid
          end
          BundleEditor.write_bundle(@bundle)
          BundleEditor.refresh_trees([@bundle.name])
          BundleEditor.reload_cache
        end
      end
    end

    class RenameSnippetGroup < Redcar::Command
      def initialize bundle,menu
        @bundle,@menu = bundle,menu
      end

      def execute
        if menu = @bundle.sub_menus[@menu]
          result = Redcar::Application::Dialog.input("Rename Snippet Menu","Choose a new name for your new snippet menu:",menu['name'])
          if result[:button] == :ok and not result[:value].empty?
            menu['name'] = result[:value]
            BundleEditor.write_bundle(@bundle)
            BundleEditor.refresh_trees([@bundle.name])
            BundleEditor.reload_cache
          end
        end
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
        result = Redcar::Application::Dialog.message_box(
          "Delete "+@node.text+" (and all children)?",{:buttons => :yes_no})
        if result == :yes
          delete(@node)
          BundleEditor.write_bundle(@node.parent.bundle)
          BundleEditor.refresh_trees([@node.parent.bundle.name])
          BundleEditor.reload_cache
        end
      end

      def delete node
        if node.children
          node.children.each do |child|
            delete(child)
          end
        end
        case node
        when SnippetNode
          case node.parent
          when BundleNode
            node.parent.bundle.main_menu['items'].delete(node.snippet.uuid)
          when SnippetGroup
            if menu = node.parent.bundle.sub_menus[node.parent.uuid]
              menu['items'].delete(node.snippet.uuid)
            else
              p "no parent found for #{node.text}"
              p "with parent #{node.parent.text} of class #{node.parent.class} (#{node.parent.uuid})"
            end
          end
          node.parent.bundle.snippets.delete(node.snippet)
          File.delete(node.snippet.path)
        when SnippetGroup
          case node.parent
          when BundleNode
            node.bundle.main_menu['items'].delete(node.uuid)
          when SnippetGroup
            node.bundle.sub_menus[node.parent.uuid]['items'].delete(node.uuid)
          end
          node.bundle.sub_menus.delete(node.uuid)
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
