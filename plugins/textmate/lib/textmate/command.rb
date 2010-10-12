module Redcar
  module Textmate
    class Command
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

      def uuid
        @plist["uuid"]
      end

      def output?
        !(@plist["output"] && @plist["output"] == "discard")
      end

      # Command to run previously to the actual command
      def before
        unless (@plist["beforeRunningCommand"].nil? || @plist["beforeRunningCommand"] == "nop")
          @plist["beforeRunningCommand"]
        end
      end

      def command
        @plist["command"]
      end

      def input
        case @plist["input"]
        when "selection"
          EditView.focussed_edit_view_document && EditView.focussed_edit_view_document.selected_text
        else # nil, "none"
          ""
        end
      end

      def to_menu_string
        r = name.clone
        r << " (#{key_equivalent})" if key_equivalent
        r
      end
    end
  end
end