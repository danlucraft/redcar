module Redcar
  class Declarations
    class SelectTagDialog < FilterListDialog

      def initialize(matches)
        super()
        @matches = matches
      end

      def close
        super
      end

      def update_list(filter)
        @last_list = @matches
        filtered_list = @last_list
        if filter.length >= 1
          filtered_list = filter_and_rank_by(filtered_list, filter, filtered_list.length) do |match|
            match[:file].split(::File::SEPARATOR).last
          end
        end
        align_matches_for_display(filtered_list)
      end

      def selected(text, ix, closing=false)
        if @last_list
          close
          Redcar::Declarations.go_to_definition(@last_list[ix])
        end
      end
      
      private
      
      def align_matches_for_display(filtered_list)
        filtered_list.collect do |match|
          file_path     = match[:file]
          file          = file_path.split(::File::SEPARATOR).last
          relative_path = file_path.gsub(Regexp.compile(Project::Manager.focussed_project.path + '/'), '')
          "%s (%s)" % [file, relative_path]
        end
      end
    end
  end
end
