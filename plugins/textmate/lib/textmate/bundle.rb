
module Redcar
  module Textmate
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
      
      def snippets
        @snippets ||= snippet_paths.map {|path| Snippet.new(path, self.name) }
      end
      
      private
      
      def preference_paths
        Dir[File.join(path, "Preferences", "*")]
      end
      
      def snippet_paths
        Dir[File.join(path, "Snippets", "*")]
      end
    end
  end
end