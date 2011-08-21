
module Redcar
  module Textmate
    class EditorController
      include Redcar::HtmlController

      def initialize snippet, tab, bundle=nil, menu=nil
        @snippet, @tab = snippet, tab
        @bundle, @menu = bundle, menu
      end

      def save content, trigger, scope
        @snippet.plist['content'] = content
        @snippet.plist['tabTrigger'] = trigger
        @snippet.plist['scope'] = scope
        File.open(@snippet.path, 'w') do |f|
          f.puts(Plist.plist_to_xml(@snippet.plist))
        end
        if @bundle
          @bundle.ordering  = [] unless @bundle.ordering
          @bundle.main_menu = {} unless @bundle.main_menu
          @bundle.main_menu['items'] = [] unless @bundle.main_menu['items']
          @bundle.main_menu['items'] << @snippet.plist['uuid']
          @bundle.ordering << @snippet.plist['uuid']
          @bundle.snippets << @snippet
          Textmate.uuid_hash[@snippet.plist['uuid']] = @snippet
          File.open(File.expand_path(File.join(@bundle.path,'info.plist')), 'w') do |f|
            f.puts(Plist.plist_to_xml(@bundle.plist))
          end
        end
        Redcar.app.windows.map {|w|
          w.treebook.trees
        }.flatten.select {|t|
          t.tree_mirror.is_a?(Redcar::Textmate::TreeMirror)
        }.each {|t|
          t.tree_mirror.refresh([@bundle.name]) if @bundle
          t.refresh
        }
        Redcar::Textmate.cache.clear
        Redcar::Textmate.cache.cache do
          Textmate.all_bundles
        end
        close_tab
      end

      def close_tab
        @tab.close if @tab
      end

      def title
        "Snippet Editor"
      end

      def resource file
        File.join(File.expand_path(File.join(File.dirname(__FILE__),'..','..','views',file)))
      end

      def index
        rhtml = ERB.new(File.read(resource("snippet_editor.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end