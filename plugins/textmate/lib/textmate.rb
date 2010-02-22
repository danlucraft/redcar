
require 'textmate/plist'

module Redcar
  module Textmate
    def self.all_bundle_paths
      Dir[File.join(Redcar.root, "textmate", "Bundles", "*")]
    end
    
    def self.all_bundles
      all_bundle_paths.map {|path| Bundle.new(path) }
    end
    
    class Bundle
      attr_reader :path
    
      def initialize(path)
        @path = File.expand_path(path)
      end
      
      def name
        File.split(path).last.gsub(/\.tmbundle/i, "")
      end
      
      def preferences
        @preferences ||= preference_paths.map {|path| Preference.new(path) }
      end
      
      private
      
      def preference_paths
        Dir[File.join(path, "Preferences", "*")]
      end
    end
    
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
      
      def settings
        @settings ||= begin
          @plist["settings"].map do |name, setting_plist|
            klass.new(setting_plist) if klass = setting_class(name)
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
      def initialize(plist)
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
    end
    
    class DecreaseIndentPatternSetting < Setting
    end
    
    class UnIndentedLinePatternSetting < Setting
    end
    
    class IndentNextLinePatternSetting < Setting
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





