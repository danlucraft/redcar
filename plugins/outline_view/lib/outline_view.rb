require "outline_view/commands"

module Redcar
  class OutlineView
    
    def self.menus
      Menu::Builder.build do
        sub_menu "View" do
          item "Current Document Outline", :command => OutlineView::OpenOutlineViewCommand, :priority => :first
        end
      end
    end
    
    def self.keymaps
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+I", OutlineView::OpenOutlineViewCommand
      end
      osx = Keymap.build("main", [:osx]) do
        link "Cmd+I", OutlineView::OpenOutlineViewCommand
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
      
      def update_list(filter)
        file = Declarations::File.new(@document.path)
        file.add_tags_for_paths([@document.path])
        re = make_regex(filter)
        @last_list.clear
        result = {}
        file.tags.each do |name, _, match|
          if name =~ re
            @last_list[match] = name
            result[match] = {:name => name, :kind => Declarations.match_kind(@document.path, match)}
          end
        end
        result
      end
      
      def selected(match, closing=true)
        if @last_list
          Redcar.app.navigation_history.save(@document)
          DocumentSearch::FindNextRegex.new(Regexp.new(Regexp.quote(match)), true).run_in_focussed_tab_edit_view
          Redcar.app.navigation_history.save(@document)
          close if closing
        end
      end
    end
  end
end
