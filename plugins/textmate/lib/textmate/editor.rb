
module Redcar
  module Textmate
    class BundleEditor
      def self.write_bundle bundle
        FileUtils.mkdir(bundle.path) unless File.exists?(bundle.path)
        File.open(File.expand_path(File.join(bundle.path,'info.plist')), 'w') do |f|
          f.puts(Plist.plist_to_xml(bundle.plist))
        end
      end

      def self.refresh_trees bundle_names=nil, inserts=nil
        Redcar.app.windows.map {|w|
          w.treebook.trees
        }.flatten.select {|t|
          t.tree_mirror.is_a?(Redcar::Textmate::TreeMirror)
        }.each {|t|
          t.tree_mirror.refresh(bundle_names,inserts) if bundle_names
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

      def self.resource file
        File.join(File.expand_path(File.join(File.dirname(__FILE__),'..','..','views',file)))
      end

      def self.create_snippet name,bundle,menu=nil
        snippet_dir = File.expand_path(File.join(@bundle.path,"Snippets"))
        FileUtils.mkdir(snippet_dir) unless File.exists?(snippet_dir)
        filename = name.gsub(/[^a-zA-Z0-9]/,"_")
        path     = generate_path(snippet_dir,filename)
        index    = 0
        while File.exists?(path)
          path = generate_path(snippet_dir, filename, index+=1)
        end
        xml   = Redcar::Plist.plist_to_xml(create_snippet_plist(name))
        temp  = Java::JavaIo::File.create_temp_file(name,'.plist')
        fake_path = temp.absolute_path
        File.open(fake_path,'w') do |f|
          f.puts(xml)
        end
        snippet = Textmate::Snippet.new(fake_path,bundle.name)
        snippet.path = path
        temp.delete
        OpenSnippetEditor.new(snippet,bundle,menu).run
      end

      def self.add_snippet_to_bundle snippet, bundle, menu=nil
        if menu
          menu = bundle.sub_menus[menu]
          bundle.sub_menus['item'] = {} unless menu
        else
          menu = bundle.main_menu
        end
        menu = {} unless menu
        menu['items'] = [] unless menu['items']
        menu['items'] << snippet.plist['uuid']
        bundle.ordering << snippet.plist['uuid'] if bundle.ordering
        bundle.snippets << snippet unless bundle.snippets.include?(snippet)
        Textmate.uuid_hash[snippet.plist['uuid']] = snippet
        write_bundle(bundle)
        reload_cache
        refresh_trees([bundle.name])
      end

      def self.update_snippet snippet, name, content, trigger, scope
        snippet.plist.tap do |p|
          p['name']    = name
          p['content'] = content
          p['scope']   = scope
          if trigger.empty?
            p.delete('tabTrigger')
          else
            p['tabTrigger'] = trigger
          end
        end
        File.open(snippet.path, 'w') do |f|
          f.puts(Plist.plist_to_xml(snippet.plist))
        end
      end

      def self.create_bundle name, bundle_dir
        path = File.expand_path(File.join(bundle_dir,name))
        path += ".tmbundle" unless path =~ /\.tmbundle$/
        if File.exists?(path)
          Redcar::Application::Dialog.message_box("A Bundle by that name already exists.")
          return
        end
        FileUtils.mkdir(bundle_dir) unless File.exists?(bundle_dir)
        FileUtils.mkdir(path)
        xml = Redcar::Plist.plist_to_xml(create_bundle_plist(name))
        fake_path = File.join(Java::JavaLang::System.getProperty("java.io.tmpdir"),'info.plist')
        File.open(fake_path,'w') do |f|
          f.puts(xml)
        end
        bundle = Bundle.new(File.dirname(fake_path))
        bundle.path = path
        File.delete(fake_path)
        OpenBundleEditor.new(bundle).run
      end

      def self.update_bundle bundle, name, description, contact_name, email
        bundle.plist.tap do |p|
          p['contactEmailRot13'] = rot13(email)
          p['contactName'] = contact_name
          p['description'] = description
          p['name'] = name
        end
        Textmate.all_bundles << bundle unless Textmate.all_bundles.include?(bundle)
        write_bundle(bundle)
        refresh_trees([],[bundle])
        reload_cache
      end

      def self.create_submenu name,bundle,menu=nil
        bundle.main_menu['submenus'] = {} unless bundle.sub_menus
        uuid = generate_id
        bundle.sub_menus[uuid] = {
          "name"  => name,
          "items" => []
        }
        if menu and bundle.sub_menus[menu]
          bundle.sub_menus[menu]['items'] << uuid
        else
          bundle.plist['mainMenu'] = {} unless bundle.main_menu
          bundle.main_menu['items'] = [] unless bundle.main_menu['items']
          bundle.main_menu['items'] << uuid
        end
        write_bundle(bundle)
        refresh_trees([bundle.name])
        reload_cache
      end

      def self.rename_submenu name,bundle,menu
        menu['name'] = name
        write_bundle(bundle)
        refresh_trees([bundle.name])
        reload_cache
      end

      def self.delete_snippet bundle,snippet, parent_menu_uuid=nil
        bundle.snippets.delete(snippet)
        File.delete(snippet.path)
        delete_item_from_parent(bundle,snippet.uuid,parent_menu_uuid)
      end

      def self.delete_submenu bundle,menu, parent_menu_uuid=nil
        bundle.sub_menus.delete(menu)
        delete_item_from_parent(bundle,snippet.uuid,parent_menu_uuid)
      end

      private

      def self.delete_item_from_parent bundle, uuid, parent_menu_uuid=nil
        if parent_menu_uuid and bundle.sub_menus[parent_menu_uuid]
          bundle.sub_menus[parent_menu_uuid]['items'].delete(uuid)
        else
          bundle.main_menu['items'].delete(uuid)
        end
      end

      def self.create_bundle_plist name
        {
          "name" => name,
          "contactName" => "",
          "contactEmailRot13" => "",
          "description" => "",
          "mainMenu" => {
            'items' => [],
            "submenus" => {}
          },
          "ordering" => [],
          "uuid" => generate_id
        }
      end

      def self.create_snippet_plist name
        {
          "name" => name,
          "uuid" => generate_id,
          "tabTrigger" => "",
          "scope" => "",
          "content" => ""
        }
      end

      def self.generate_path(dir, filename, index=nil)
        File.expand_path(File.join(dir,"#{filename}#{index ? index : ''}.plist"))
      end
    end
  end
end