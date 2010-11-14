module Redcar
  class EditView
    class SelectThemeDialog < FilterListDialog

      def initialize
        super()
        @matches = EditView.themes.sort
        @matches.delete(EditView.theme)
        @matches.insert(0, EditView.theme + " (Current)")
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
          Redcar::EditView.theme = text
        end
      end

      def moved_to(text, ix)
        if @last_list
          Redcar::EditView.theme = text
        end
      end

    end
  end
end
