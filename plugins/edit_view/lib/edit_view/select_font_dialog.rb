module Redcar
  class EditView
    class SelectFontDialog < FilterListDialog

      def initialize
        super()
        fontdata = Redcar.app.focussed_window.controller.shell.get_display.get_font_list(nil, true)
        @matches = []
        (0..(fontdata.length-1)).each do |i|
          @matches << fontdata[i].get_name unless @matches.include?(fontdata[i].get_name)
        end
        @matches.sort!
      end

      def close
        super
      end

      def update_list(filter)
        @last_list = @matches
        filtered_list = @last_list
        if filter.length >= 1
          filtered_list = filter_and_rank_by(filtered_list, filter, filtered_list.length) do |match|
            match
          end
        end
        filtered_list
      end

      def selected(text, ix, closing=false)
        if @last_list
          close
          Redcar::EditView.font = text
        end
      end

      def moved_to(text, ix)
        if @last_list
          Redcar::EditView.font = text
        end
      end

    end
  end
end
