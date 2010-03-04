
module Redcar
  module Textmate
    class Snippet
      attr_reader :bundle_name
    
      def initialize(path, bundle_name)
        @path = path
        @plist = Plist.xml_to_plist(File.read(path))
        @bundle_name = bundle_name
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