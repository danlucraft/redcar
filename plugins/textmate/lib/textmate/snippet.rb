module Redcar
  module Textmate
    class Snippet
      attr_reader :bundle_name, :key_equivalent
    
      def initialize(path, bundle_name)
        @path = path
        @plist = Plist.xml_to_plist(File.read(path))
        @bundle_name = bundle_name
        if key = @plist["keyEquivalent"]
          @key_equivalent = Textmate.translate_key_equivalent(key)
        end
      end
      
      def name
        @plist["name"]
      end
      
      def scope
        @plist["scope"]
      end
      
      def uuid
        @plist["uuid"]
      end
      
      def tab_trigger
        @plist["tabTrigger"]
      end
      
      def content
        @plist["content"]
      end
      
      def to_menu_string
        r = name.clone
        # It doesn't seem to be possible to set accelerator text on OSX.
        if Redcar.platform == :osx
          r << " (#{tab_trigger}↦)" if tab_trigger
        else
          r << "\t#{tab_trigger}" if tab_trigger
        end
        r
      end
    end
  end
end