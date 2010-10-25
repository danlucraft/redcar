
require 'java'

module Redcar
  class WebBookmarks

    # Open a HtmlTab for displaying web content
    class DisplayWebContent < Redcar::Command
      def initialize(name,url,display_bar=true)
        @name = name
        @url  = url
        @display_bar = display_bar
      end

      def execute
        win = Redcar.app.focussed_window
        controller = ViewController.new(@name,@url)
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
        if @display_bar or
          WebBookmarks.storage['show_browser_bar_on_start']
          WebBookmarks::OpenBrowserBar.new.run
        end
      end
    end

    class FileWebPreview < Redcar::EditTabCommand
      def execute
        mirror  = doc.mirror
        if mirror and path = mirror.path and File.exists?(path)
          name = "Preview: " +File.basename(path)
        else
          name    = "Preview: (untitled)"
          preview = java.io.File.createTempFile("preview","html")
          preview.deleteOnExit
          path    = preview.getAbsolutePath
          File.open(path,'w') {|f| f.puts(doc.get_all_text)}
        end
        url  = "file://" + path
        DisplayWebContent.new(name,url).run
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

    class AddBookmark < Redcar::ProjectCommand
      def initialize(url)
        @protocol = url.split("://")[0]
        @url      = url.split("://")[1]
      end

      def execute
        @path = project.config_files(BOOKMARKS_FILE).detect { |pj|
           not pj.include?(Redcar.user_dir)
        }
        if @path
          json = File.read(@path)
        else
          @path = project.path + "/.redcar/#{BOOKMARKS_FILE}"
          json = JSON.generate({"bookmarks"=>[]})
        end
        bookmarks = JSON(json)["bookmarks"]
        if name = fill_field("Name")
          group = fill_field("Group")
          bookmark = {
            "name"     => name,
            "url"      => @url,
            "protocol" => @protocol
          }
          bookmark["group"] = group unless group.nil? or group == ""
          bookmarks << bookmark
          File.open(@path,'w') do |f|
            f.puts JSON.pretty_generate({"bookmarks"=>bookmarks})
          end
        end
      end

      def fill_field(name)
        title = "Add New Bookmark"
        msg   = "Choose a #{name} for this Bookmark"
        out   = Redcar::Application::Dialog.input(title,msg)
        return if out[:button] == :cancel
        name = out[:value]
      end
    end
  end
end