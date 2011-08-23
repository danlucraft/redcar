
module Redcar
  module Textmate
    class BundleEditor
      def self.write_bundle bundle
        File.open(File.expand_path(File.join(bundle.path,'info.plist')), 'w') do |f|
          f.puts(Plist.plist_to_xml(bundle.plist))
        end
      end

      def self.refresh_trees bundle_names=nil
        Redcar.app.windows.map {|w|
          w.treebook.trees
        }.flatten.select {|t|
          t.tree_mirror.is_a?(Redcar::Textmate::TreeMirror)
        }.each {|t|
          t.tree_mirror.refresh(bundle_names) if bundle_names
          t.refresh
        }
      end

      def self.reload_cache
        Redcar::Textmate.cache.clear
        Redcar::Textmate.cache.cache do
          Textmate.all_bundles
        end
      end

      def self.generate_id
        Java::JavaUtil::UUID.randomUUID.to_s.upcase
      end

      def self.rot13 email
        email.tr("A-Za-z", "N-ZA-Mn-za-m")
      end
    end

    class EditorController
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
          @bundle.snippets << @snippet
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