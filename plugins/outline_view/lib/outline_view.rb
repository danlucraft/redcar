require "outline_view/commands"

module Redcar
  class OutlineView
    class OutlineViewDialog < FilterListDialog
      
      attr_accessor :document
      attr_accessor :last_list
      
      def initialize(document)
        super()
        @document = document
        @last_list = Hash.new
      end
      
      def get_tags_for_path(path)
        Declarations.tags_for_path(path)
      end
      
      def close
        super
      end
      
      def update_list(filter)
        file = Declarations::File.new(@document.path)
        file.add_tags_for_paths([@document.path])
        re = make_regex(filter)
        @last_list.clear
        file.tags.each do |key, _, match|
          @last_list[key] = make_regex(match) if key =~ re
        end
        @last_list.keys
      end
      
      def selected(text, ix, closing=false)
        if @last_list
          close
          DocumentSearch::FindNextRegex.new(@last_list[text], true).run
        end
      end
    end
  end
end
