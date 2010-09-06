module Swt
  module Layout
    class GridData
      def self.construct
        layoutData = GridData.new
        yield layoutData
        layoutData
      end
    end
  end
end
