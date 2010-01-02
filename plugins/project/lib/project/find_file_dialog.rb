module Redcar
  class Project
    class FindFileDialog < FilterListDialog
    
      def starting_list
        %w(do re me fa so la ti da)
      end
      
      def update_list(filter)
        filter.split //
      end
    end
  end
end
