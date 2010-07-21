
require 'textmate/bundle'
require 'textmate/environment'
require 'textmate/plist'
require 'textmate/preference'
require 'textmate/snippet'

module Redcar
  module Textmate
    def self.all_bundle_paths
      Dir[File.join(Redcar.root, "textmate", "Bundles", "*")]
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
    
    def self.attach_menus(builder)
      #@menus ||= begin
      #  Menu::Builder.build do |a|
      #    all_bundles.sort_by {|b| (b.name||"").downcase}.each do |bundle|
      #      bundle.build_menu(a)
      #    end
      #  end
      #end
      #@menus.entries.each {|i| builder.append(i) }
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
    rescue NameError => e    
      puts "Delaying full textmate plugin while installing."
    end
  end
end





