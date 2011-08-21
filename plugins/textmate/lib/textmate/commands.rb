
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

    class OpenSnippetEditor < Redcar::Command
      def initialize snippet
          @snippet = snippet
      end

      def execute
        tab = Redcar.app.focussed_window.new_tab(Redcar::HtmlTab)
        tab.html_view.controller = Controller.new(@snippet,tab)
        tab.icon = :edit_code
        tab.focus
      end

      class Controller
        include Redcar::HtmlController

        def initialize snippet, tab
          @snippet, @tab = snippet, tab
        end

        def save content, trigger, scope
          @snippet.plist['content'] = content
          @snippet.plist['tabTrigger'] = trigger
          @snippet.plist['scope'] = scope
          File.open(@snippet.path, 'w') do |f|
            f.puts(Plist.plist_to_xml(@snippet.plist))
          end
          Redcar.app.windows.map {|w|
            w.treebook.trees
          }.flatten.select {|t|
            t.tree_mirror.is_a?(Redcar::Textmate::TreeMirror)
          }.each {|t| t.refresh }
          close_tab
        end

        def close_tab
          @tab.close if @tab
        end

        def title
          "Snippet Editor"
        end

        def resource file
          File.join(File.expand_path(File.join(File.dirname(__FILE__),'..','..','views',file)))
        end

        def index
          rhtml = ERB.new(File.read(resource("snippet_editor.html.erb")))
          rhtml.result(binding)
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
