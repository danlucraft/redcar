
require 'textmate/bundle'
require 'textmate/environment'
require 'textmate/plist'
require 'textmate/preference'
require 'textmate/snippet'
require 'textmate/editor/drag_controller'
require 'textmate/tree_mirror'
require 'textmate/editor'
require 'textmate/editor/bundle_controller'
require 'textmate/editor/snippet_controller'
require 'textmate/commands'

gem "redcar-bundles"
require 'redcar-bundles'

module Redcar
  module Textmate
    def self.user_bundle_dir
      File.join(Redcar.user_dir, "Bundles")
    end

    def self.all_bundle_paths
      @all_bundle_paths = Dir[File.join(user_bundle_dir, "*")]
      @all_bundle_paths += Dir[File.join(RedcarBundles.dir, "Bundles", "*")]
      Redcar.plugin_manager.loaded_plugins.each do |plugin|
        @all_bundle_paths += Dir[File.join(File.dirname(plugin.definition_file), "Bundles", "*")]
      end
      @all_bundle_paths
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Bundles" do
          if Textmate.storage['loaded_bundles'].size() > 0 and Textmate.storage['load_bundles_menu']
            item "Clear Bundle Menu", :command => ClearBundleMenu, :priority => 20
          end
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", [:osx]) do
        link "Cmd+Shift+B", ShowSnippetTree
      end
      lin = Redcar::Keymap.build("main", [:windows,:linux]) do
        link "Ctrl+Shift+B", ShowSnippetTree
      end
      [osx,lin]
    end

    def self.toolbars
      Redcar::ToolBar::Builder.build do
        item "Snippet Browser", :command => Textmate::ShowSnippetTree, :icon => File.join(Redcar.icons_directory, "document-tree.png"), :barname => :help
      end
    end

    def self.bundle_context_menus(tree,node)
      Menu::Builder.build do
        if not node.nil?
          if node.children.size > 0
            item("Sort") do
              SortNodes.new(tree,node).run
            end
          end
          case node
          when BundleNode
            item("Edit Bundle") do
              OpenBundleEditor.new(node.bundle).run
            end
            item("Add new Snippet...") do
              CreateNewSnippet.new(node.bundle).run
            end
            item("Add new Snippet Menu...") do
              CreateNewSnippetGroup.new(tree, node).run
            end
            if Textmate.storage['load_bundles_menu']
              if Textmate.storage['loaded_bundles'].include?(node.text.downcase)
                item ("Remove from Bundles Menu") do
                  RemovePinnedBundle.new(node.text).run
                end
              else
                item("Pin to Bundles Menu") do
                  PinBundleToMenu.new(node.text).run
                end
              end
            end
          when SnippetNode
            item("Edit Snippet") do
              OpenSnippetEditor.new(node.snippet).run
            end
            item("Delete Snippet") do
              DeleteNode.new(node).run
            end
          when SnippetGroup
            item("Rename...") do
              RenameSnippetGroup.new(tree,node).run
            end
            item("Add new Snippet...") do
              CreateNewSnippet.new(node.bundle,node.uuid).run
            end
            item("Add new Snippet Menu...") do
              CreateNewSnippetGroup.new(tree, node).run
            end
            item("Delete Menu") do
              DeleteNode.new(node).run
            end
          end
        end
        item("Create new Bundle") do
          CreateNewBundle.new.run
        end
      end
    end

    def self.refresh_tree
      win = Redcar.app.focussed_window
      if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
        tree.refresh
      end
    end

    def self.uuid_hash
      @uuid_hash ||= begin
        h = {}
        all_bundles.each do |b|
          if h[b.uuid].nil?
            h[b.uuid] = b
            b.snippets.each {|s| h[s.uuid] = s }
            b.preferences.each {|p| h[p.uuid] = p }
          end
        end
        h
      end
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('textmate')
        storage.set_default('load_bundles_menu',false)
        storage.set_default('select_bundles_for_menu',true)
        storage.set_default('select_bundles_for_tree',false)
        storage.set_default('loaded_bundles',[])
        storage
      end
    end

    def self.attach_menus(builder)
      if Textmate.storage['load_bundles_menu']
        Menu::Builder.build do |a|
          Textmate.all_bundles.sort_by {|b| (b.name||"").downcase}.each do |bundle|
            name = (bundle.name||"").downcase
            unless Textmate.storage['select_bundles_for_menu'] and not Textmate.storage['loaded_bundles'].to_a.include?(name)
              bundle.build_menu(a).each do |c|
                builder.append(c)
              end
            end
          end
        end
      end
    end

    def self.cache
      @cache ||= PersistentCache.new("textmate_bundles")
    end

    def self.all_bundles
      @all_bundles ||= begin
        cache.cache do
          dups = []
          uuids = []
          bundles = all_bundle_paths.map {|path|
            b = Bundle.new(path)
            dups << b.uuid if uuids.include?(b.uuid)
            uuids << b.uuid
            b
          }
          bundles.reject! {|b|
            dups.include?(b.uuid) and File.dirname(b.path) != user_bundle_dir}
          bundles
        end
      end
    end

    def self.all_snippets
      @all_snippets ||= begin
        all_bundles.map {|b| b.snippets }.flatten
      end
    end

    def self.all_settings
      @all_settings ||= begin
        all_bundles.map {|b| b.preferences }.flatten.map {|p| p.settings}.flatten
      end
    end

    def self.settings(type=nil)
      @all_settings_by_type ||= {}
      @all_settings_by_type[type] ||= all_settings.select {|s| s.is_a?(type) }
    end

    # Translates a Textmate key equivalent into a Redcar keybinding.
    def self.translate_key_equivalent(keyeq, name=nil)
      if keyeq
        key_str      = keyeq[-1..-1]
        case key_str
        when "\n"
          letter = "Return"
        else
          letter = key_str.gsub("\e", "Escape")
        end
        modifier_str = keyeq[0..-2]
        modifiers = modifier_str.split("").map do |modchar|
          case modchar
          when "^" # TM: Control
            [2, "Ctrl"]
          when "~" # TM: Option
            [3, "Alt"]
          when "@" # TM: Command
            [1, "Super"]
          when "$"
            [4, "Shift"]
          else
            return nil
          end
        end
        if letter =~ /^[[:alpha:]]$/ and letter == letter.upcase
          modifiers << [4, "Shift"]
        end
        modifiers = modifiers.sort_by {|a| a[0]}.map{|a| a[1]}.uniq
        res = if modifiers.empty?
          letter
        else
          modifiers.join("+") + "+" + (letter.length == 1 ? letter.upcase : letter)
        end
        res
      end
    end

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
  end
end
