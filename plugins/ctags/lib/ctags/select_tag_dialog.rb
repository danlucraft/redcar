module Redcar
  class CTags
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
            match[:file].split(File::SEPARATOR).last
          end
        end
        filtered_list.collect do |match|
          file_path    =  match[:file]
          display_item =  file_path.split(File::SEPARATOR).last
          display_item += "\t\t"
          display_item += ' ('
          display_item += file_path.gsub(Regexp.compile(Redcar::Project.focussed_project_path + '/'), '')
          display_item += ')'
        end
      end

      def selected(text, ix, closing=false)
        if @last_list
          close
          Redcar::CTags.go_to_definition(@last_list[ix])
        end
      end
    end
  end
end
