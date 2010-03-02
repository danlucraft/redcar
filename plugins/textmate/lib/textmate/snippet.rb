
module Redcar
  module Textmate
    class Snippet
      def initialize(path)
        @path = path
        @plist = Plist.xml_to_plist(File.read(path))
      end
      
      def name
        @plist["name"]
      end
      
      def scope
        @plist["scope"]
      end
      
      def tab_trigger
        @plist["tabTrigger"]
      end
      
      def content
        @plist["content"]
      end
    end
  end
end