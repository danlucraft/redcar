
module Redcar
  module Textmate
    class SnippetEditorController
      include Redcar::HtmlController

      def initialize snippet, tab, bundle=nil, menu=nil
        @snippet, @tab = snippet, tab
        @bundle, @menu = bundle, menu
      end

      def save name, content, trigger, scope
        BundleEditor.update_snippet @snippet, name, content, trigger, scope
        if @bundle
          BundleEditor.add_snippet_to_bundle(@snippet, @bundle, @menu)
        else
          BundleEditor.refresh_trees
        end
        close_tab
      end

      def close_tab
        @tab.close if @tab
      end

      def title
        "Snippet Editor"
      end

      def index
        rhtml = ERB.new(File.read(BundleEditor.resource("snippet_editor.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end