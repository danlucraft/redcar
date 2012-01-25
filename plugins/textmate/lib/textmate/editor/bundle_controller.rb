
module Redcar
  module Textmate
    class BundleEditorController
      include Redcar::HtmlController

      def title
        "Bundle Editor"
      end

      def initialize bundle, tab
        @bundle, @tab = bundle, tab
      end

      def save name, description, contact_name, email
        BundleEditor.update_bundle @bundle, name, description, contact_name, email
        close_tab
      end

      def close_tab
        @tab.close if @tab
      end

      def index
        rhtml = ERB.new(File.read(BundleEditor.resource("bundle_editor.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end