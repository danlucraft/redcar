
require 'java'

module Redcar
  class WebBookmarks

    class ShowWebBookmarksCommand < Redcar::Command
      sensitize :open_project
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
          tree.refresh
          win.treebook.focus_tree(tree)
        else
          project = Project::Manager.in_window(win)
          tree = Tree.new(
            TreeMirror.new(project),
            TreeController.new(project,TREE_TITLE)
          )
          win.treebook.add_tree(tree)
        end
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
          @path = project.config_dir + "/#{BOOKMARKS_FILE}"
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