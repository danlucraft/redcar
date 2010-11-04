
module Redcar
  class ClipboardViewer
    class BrowserController
      include HtmlController

      def initialize(list)
        @list = list.to_a.reverse
      end

      def title
        "Clipboard History"
      end

      def copy(idx)
        text = @list[idx]
        Redcar.app.clipboard >> text if text
        false
      end

      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..","..", "views", "clipboard.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end