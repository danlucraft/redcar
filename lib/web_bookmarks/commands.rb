module Redcar
  class WebBookmarks

    # Open a HtmlTab for displaying web content
    class DisplayWebContent < Redcar::Command
      def initialize(name,url)
        @name = name
        @url  = url
      end

      def execute
        win = Redcar.app.focussed_window
        controller = ViewController.new(@name,@url)
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
        if WebBookmarks.storage['show_browser_bar_on_start']
          WebBookmarks::OpenBrowserBar.new.run
        end
      end
    end

    class ShowTree < Redcar::Command
      sensitize :open_project
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
          tree.refresh
          win.treebook.focus_tree(tree)
        else
          project = Project::Manager.in_window(win)
          tree = Tree.new(
            TreeMirror.new(project),
            TreeController.new(project)
          )
          win.treebook.add_tree(tree)
        end
      end
    end

    class OpenBrowserBar < Redcar::Command
      def execute
        window = Redcar.app.focussed_window
        speedbar = Redcar::WebBookmarks::BrowserBar.new
        window.open_speedbar(speedbar)
      end
    end
  end
end