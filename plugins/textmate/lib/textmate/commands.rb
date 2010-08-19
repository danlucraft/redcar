
module Redcar
  module Textmate

    class ClearBundleMenu < Redcar::Command
      def execute
        Textmate.storage['loaded_bundles'] = []
        ReloadSnippetTree.new.run
        Redcar.app.refresh_menu!
      end
    end

    class RemovePinnedBundle < Redcar::Command
      def initialize(bundle_name)
        @bundle_name = bundle_name.downcase
      end

      def execute
        unless not Textmate.storage['loaded_bundles'].include?(@bundle_name)
          bundles = Textmate.storage['loaded_bundles'] || []
          bundles.delete(@bundle_name)
          Textmate.storage['loaded_bundles'] = bundles
          ReloadSnippetTree.new.run
          Redcar.app.refresh_menu!
        end
      end
    end

    class PinBundleToMenu < Redcar::Command
      def initialize(bundle_name)
        @bundle_name = bundle_name.downcase
      end

      def execute
        unless Textmate.storage['loaded_bundles'].include?(@bundle_name)
          bundles = Textmate.storage['loaded_bundles'] || []
          bundles << @bundle_name
          Textmate.storage['loaded_bundles'] = bundles
          ReloadSnippetTree.new.run
          Redcar.app.refresh_menu!
        end
      end
    end
  end
end
