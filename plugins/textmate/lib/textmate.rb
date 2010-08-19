
require 'textmate/bundle'
require 'textmate/environment'
require 'textmate/plist'
require 'textmate/preference'
require 'textmate/snippet'
begin
  require 'textmate/tree_mirror'
  require 'textmate/commands'
rescue NameError => e
  puts "Core loading not yet complete"
  # In the installer we don't have all of core loaded yet
end

module Redcar
  module Textmate
    def self.all_bundle_paths
      Dir[File.join(Redcar.root, "plugins", "textmate", "vendor", "redcar-bundles", "Bundles", "*")] +
        Dir[File.join(Redcar.user_dir, "Bundles", "*")]
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Bundles" do
          if Textmate.storage['loaded_bundles'].size() > 0
            item "Clear Bundle Menu" do
              ClearBundleMenu.new.run
            end
          end
        end
      end
    end

    def self.bundle_context_menus(node)
      Menu::Builder.build do
        if not node.nil? and node.is_a?(Textmate::BundleNode)
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
      end
    end

    def self.uuid_hash
      @uuid_hash ||= begin
        h = {}
        all_bundles.each do |b|
          h[b.uuid] = b
          b.snippets.each {|s| h[s.uuid] = s }
          b.preferences.each {|p| h[p.uuid] = p }
        end
        h
      end
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('textmate')
        storage.set_default('load_bundles_menu',true)
        storage.set_default('select_bundles_for_menu',true)
        storage.set_default('select_bundles_for_tree',false)
        storage.set_default('loaded_bundles',[])
        storage
      end
    end

    def self.attach_menus(builder)
      if Textmate.storage['load_bundles_menu']
        @menus = begin
          Menu::Builder.build do |a|
            all_bundles.sort_by {|b| (b.name||"").downcase}.each do |bundle|
              name = (bundle.name||"").downcase
              unless @storage['select_bundles_for_menu'] and !@storage['loaded_bundles'].to_a.include?(name)
                bundle.build_menu(a)
              end
            end
          end
        end
        @menus.entries.each {|i| builder.append(i) }
      end
    end

    def self.all_bundles
      @all_bundles ||= begin
        cache = PersistentCache.new("textmate_bundles")
        cache.cache do
          all_bundle_paths.map {|path| Bundle.new(path) }
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
    rescue  NameError => e
      puts "Core loading not yet complete"
    end
  end
end
