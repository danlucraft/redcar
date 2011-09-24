require "outline_view/commands"

module Redcar
  class OutlineView
    
    def self.menus
      Menu::Builder.build do
        sub_menu "View" do
          item "Current Document Outline", :command => OutlineView::OpenOutlineViewCommand, :priority => :first
          item "Project Outline", :command => OutlineView::OpenProjectOutlineViewCommand, :priority => :first
        end
      end
    end
    
    def self.keymaps
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+I", OutlineView::OpenOutlineViewCommand
        link "Ctrl+Shift+I", OutlineView::OpenProjectOutlineViewCommand
      end
      osx = Keymap.build("main", [:osx]) do
        link "Cmd+I", OutlineView::OpenOutlineViewCommand
        link "Cmd+Shift+I", OutlineView::OpenProjectOutlineViewCommand
      end
      [linwin, osx]
    end
    
    class OutlineViewDialog < FilterListDialog
      include Redcar::Model
      include Redcar::Observable
      
      attr_accessor :document
      attr_accessor :last_list
      
      def initialize(document)
        self.controller = Redcar::OutlineViewSWT.new(self)
        @document = document
        @last_list = {}
      end
      
      def close
        super
      end

      def paths_map
        @paths_map ||= {}
      end

      def get_paths
        [@document.path]
      end

      def update_list(filter)
        paths = get_paths
        file = Declarations::File.new(paths.first)
        file.add_tags_for_paths(paths)
        re = make_regex(filter)
        @last_list.clear
        result = {}
        file.tags.each do |name, path, match|
          if name =~ re
            @last_list[match] = name
            paths_map[match] = path
            result[match] = {:name => name, :kind => Declarations.match_kind(path, match)}
          end
        end
        result
      end

      def selected(match, closing=true)
        if @last_list
          if path = paths_map[match] and File.exists? path
            close if closing
            Redcar::Project::Manager.open_file(path)
            Redcar.app.navigation_history.save(@document) if @document
            DocumentSearch::FindNextRegex.new(Regexp.new(Regexp.quote(match)), true).run_in_focussed_tab_edit_view
            Redcar.app.navigation_history.save(@document) if @document
          end
        end
      end
    end

    class ProjectOutlineViewDialog < OutlineViewDialog
      def initialize(project)
        @project = project
        if tab = Redcar.app.focussed_notebook_tab and tab.is_a? Redcar::EditTab
          @document = tab.edit_view.document
        end
        self.controller = Redcar::OutlineViewSWT.new(self)
        @last_list = {}
      end

      def get_paths
        @project.all_files
      end
    end
  end
end
