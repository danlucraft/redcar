
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

    begin
      class InstalledBundles < Redcar::Command
        def execute
          controller = Controller.new
          tab = win.new_tab(HtmlTab)
          tab.html_view.controller = controller
          tab.focus
        end

        class Controller
          include Redcar::HtmlController

          def title
            "Installed Bundles"
          end

          def index
            rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "installed_bundles.html.erb")))
            rhtml.result(binding)
          end
        end
      end
    rescue NameError => e
      puts "Delaying full textmate plugin while installing."
    end
  end
end