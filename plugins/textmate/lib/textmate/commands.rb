
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

    class CreateNewSnippet < Redcar::Command
      def initialize bundle
        @bundle = bundle
      end

      def generate_path(dir, filename, index=nil)
        File.expand_path(File.join(dir,"#{filename}#{index ? index : ''}.plist"))
      end

      def execute
        result = Redcar::Application::Dialog.input("Create Snippet","Choose a name for your new snippet:")
        if result[:button] == :ok and not result[:value].empty?
          snippet_dir = File.expand_path(File.join(@bundle.path,"Snippets"))
          File.mkdirs(snippet_dir) unless File.exists?(snippet_dir)
          name = result[:value]
          filename = name.gsub(/[^a-zA-Z0-9]/,"_")
          path = generate_path(snippet_dir,filename)
          index = 0
          while File.exists?(path)
            path = generate_path(snippet_dir, filename, index+=1)
          end
          plist = {
            "name" => name,
            "uuid" => Java::JavaUtil::UUID.randomUUID.to_s.upcase,
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
          OpenSnippetEditor.new(snippet,@bundle).run
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
        tab.html_view.controller = Textmate::EditorController.new(@snippet,tab,@bundle,@menu)
        tab.icon = :edit_code
        tab.focus
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
