module Redcar
  class CTags
    class SelectTagDialog < FilterListDialog

      def close
        super
      end

      def update_list(filter)
        @last_list = Redcar::CTags.matches
        filtered_list = @last_list
        if filter.length > 1
          # TODO use Redcar::FilterListDialog#filter_and_rank_by
          filtered_list = @last_list.reject do |match|
            !(match[:file].split(File::SEPARATOR).last =~ Regexp.compile("^" + filter))
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
          # FIXME Redcar::CTags::GoToTagCommand.new(match).run
          go_definition(@last_list[ix])
        end
      end # selected

      # FIXME duplicate from ctags.rb
      # Crashes when trying to
      # Redcar::CTags::GoToTagCommand.new(match).run
      def go_definition(match)
        path   = match[:file]
        if tab = Redcar::Project.open_file_tab(path)
          tab.focus
        else
          Redcar::Project.open_file(path)
        end
        regstr = "^#{Regexp.escape(match[:regexp])}$"
        regexp = Regexp.new(regstr)
        Redcar::Top::FindNextRegex.new(regexp, true).run
      end # go_definition
    end # SelectTagDialog
  end # CTags
end # Redcar
