
module Redcar
  module Textmate
    class Preference
      attr_reader :path
      
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
      
      def uuid
        @plist["uuid"]
      end
      
      def settings
        @settings ||= begin
          @plist["settings"].map do |name, setting_plist|
            if klass = setting_class(name)
              klass.new(scope, setting_plist)
            end
          end
        end
      end
      
      private
      
      def setting_class(name)
        begin
          Textmate.const_get(name.gsub(/^(\w)/) {|l| l.upcase } + "Setting")
        rescue
          puts "Couldnt find Setting class for textmate setting: #{name}"
        end
      end
    end
    
    class Setting
      attr_reader :scope, :plist
    
      def initialize(scope, plist)
        @scope = scope
        @plist = plist
      end
    end
    
    class ShellVariablesSetting < Setting
    end
    
    class SmartTypingPairsSetting < Setting
      def pairs
        @plist
      end
    end
    
    class CompletionCommandSetting < Setting
    end
    
    class CompletionsSetting < Setting
    end
    
    class IncreaseIndentPatternSetting < Setting
      def pattern; @plist; end
    end
    
    class DecreaseIndentPatternSetting < Setting
      def pattern; @plist; end
    end
    
    class UnIndentedLinePatternSetting < Setting
      def initialize(plist, scope)
        @plist = plist
        @scope = @scope || ""
      end
      def pattern; @plist; end
    end
    
    class IndentNextLinePatternSetting < Setting
      def pattern; @plist; end
    end
    
    class ShowInSymbolListSetting < Setting
    end
    
    class SymbolTransformationSetting < Setting
    end
    
    class HighlightPairsSetting < Setting
    end
    
    class SpellCheckingSetting < Setting
    end
    
    class DisableDefaultCompletionSetting < Setting
    end
    
    class BackgroundSetting < Setting
    end
    
    class ForegroundSetting < Setting
    end
    
    class FontStyleSetting < Setting
    end
    
    class CommentSetting < Setting
    end
    
    class BoldSetting < Setting
    end
    
    class ItalicSetting < Setting
    end
    
    class UnderlineSetting < Setting
    end
  end
end