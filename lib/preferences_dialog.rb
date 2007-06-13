
#preferences "Macros" do |p|
#  p.add "Name", :type => :string, :default => "Untitled Macro"
#  p.add "Macros enabled", :type => :toggle, :default => :true
#end

module Redcar
  module Preferences
    module ClassMethods
      def preferences(plugin_name=self.class, &block)
        @plugin_name = plugin_name
        builder = PreferencesBuilder.new
        yield builder
        Redcar::Preferences.register_preferences(@plugin_name, builder)
      end
      
      def Preferences
        Redcar::Preferences::Preferences.new(@plugin_name)
      end
    end
    
    def self.included(klass)
      klass.extend(ClassMethods)
    end
    
    def self.register_preferences(plugin_name, builder)
      @preferences ||= {}
      @preferences[plugin_name] = builder.prefs
      @preferences[plugin_name].each do |pref_name, pref_hash|
        path =  "preferences/"+plugin_name+"/"
        Redcar[path+pref_name+"/type"] ||= pref_hash[:type].to_s
        Redcar[path+pref_name+"/value"] ||= pref_hash[:default]
      end
    end
    
    def self.widget(name)
      Gtk::Frame.new
    end
    
    class PreferencesBuilder
      attr_reader :prefs
      def initialize
        @prefs = {}
      end
      
      def add(name, options)
        options = process_params(options,
                                 { :type => :MANDATORY,
                                   :default => "" })
        @prefs[name] = options
      end
    end
    
    class Preferences
      def initialize(plugin_name)
        @plugin_name = plugin_name
        @path =  "preferences/"+@plugin_name+"/"
      end
      
      def [](n)
        Redcar[@path+n+"/value"]
      end
      
      def []=(n, v)
        Redcar[@path+n+"/value"] = v
      end
    end
  end
  class PreferencesDialog
    def initialize
      @glade = GladeXML.new("lib/glade/preferences-dialog.glade",
                            nil,
                            "Redcar",
                            nil,
                            GladeXML::FILE) do |handler|
        method(handler)
      end
    end
  end
end
