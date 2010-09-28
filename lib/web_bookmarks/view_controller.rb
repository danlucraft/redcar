
module Redcar
  class WebBookmarks
    class ViewController
      include HtmlController

      def initialize(title,url)
        @title = title
        @url = url
      end

      def title
        @title
      end

      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..","..", "views", "index.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end