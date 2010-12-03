
module Redcar
  module Scm
    class DiffMirror
      include Redcar::Document::Mirror

      def initialize(change, diff)
        @change = change
        @diff = diff
      end

      def title
        "Diff: #{File.basename(@change.path)}"
      end

      def exists?
        true
      end

      # Diffs don't change. Each time the tree is refreshed, new Change
      # objects are created.
      def changed?
        false
      end

      def read
        @diff
      end
    end
  end
end
