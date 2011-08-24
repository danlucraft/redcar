
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
        @bundle.plist.tap do |p|
          p['contactEmailRot13'] = BundleEditor.rot13(email)
          p['contactName'] = contact_name
          p['description'] = description
          p['name'] = name
        end
        Textmate.all_bundles << @bundle unless Textmate.all_bundles.include?(@bundle)
        BundleEditor.write_bundle(@bundle)
        BundleEditor.refresh_trees([],[@bundle])
        BundleEditor.reload_cache
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