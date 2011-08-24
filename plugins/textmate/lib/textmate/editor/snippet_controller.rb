
module Redcar
  module Textmate
    class SnippetEditorController
      include Redcar::HtmlController

      def initialize snippet, tab, bundle=nil, menu=nil
        @snippet, @tab = snippet, tab
        @bundle, @menu = bundle, menu
      end

      def save name, content, trigger, scope
        @snippet.plist['name'] = name
        @snippet.plist['content'] = content
        if trigger.empty?
          @snippet.plist.delete('tabTrigger')
        else
          @snippet.plist['tabTrigger'] = trigger
        end
        @snippet.plist['scope'] = scope
        File.open(@snippet.path, 'w') do |f|
          f.puts(Plist.plist_to_xml(@snippet.plist))
        end
        if @bundle
          if @menu
            menu = @bundle.sub_menus[@menu]
            @bundle.sub_menus['item'] = {} unless menu
          else
            menu = @bundle.main_menu
          end
          menu = {} unless menu
          menu['items'] = [] unless menu['items']
          menu['items'] << @snippet.plist['uuid']
          @bundle.ordering << @snippet.plist['uuid']
          @bundle.snippets << @snippet unless @bundle.snippets.include?(@snippet)
          Textmate.uuid_hash[@snippet.plist['uuid']] = @snippet
          BundleEditor.write_bundle(@bundle)
        end
        BundleEditor.reload_cache
        if @bundle
          BundleEditor.refresh_trees([@bundle.name])
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