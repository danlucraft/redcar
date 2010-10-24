module Redcar
  module SyntaxCheck
    class Checker
      attr_reader :doc

      def self.checkers
        @checkers ||= {}
      end

      def self.[] name
        checkers[name]
      end

      def self.supported_grammars(*names)
        if names.any?
          names.each {|g| Checker.checkers[g] = self }
          @supported_grammars = supported_grammars + names
        else
          @supported_grammars ||= []
        end
      end

      def initialize(document)
        @doc = document
      end

      def manifest_path(doc = @doc)
        path = doc.path
        unless path and File.exist? path
          Tempfile.open(doc.title) do |f|
            f << doc.get_all_text
            path = f.path
          end
        end
        path
      end

      def supported_grammars
        raise NotImplementedError, "My subclass #{self.class.name} should have implemented check"
      end

      def check
        raise NotImplementedError, "My subclass #{self.class.name} should have implemented check"
      end
    end
  end
end