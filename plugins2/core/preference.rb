
module Redcar
  module Preference
    extend FreeBASE::StandardPlugin
    
    def self.load(plugin)
      FreeBASE::Properties.new("Redcar Preferences", 
                               Redcar::VERSION, 
                               bus('/redcar/preferences'), 
                               File.dirname(__FILE__) + "/../../custom/preferences.yaml")
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.get(scope, name)
      bus("/redcar/preferences/#{scope}/#{name}").data
    end
  end
  
  module PreferenceBuilder
    def Preference(name, &block)
      plugin_scope = self.to_s
      PreferenceBuilder.clear
      PreferenceBuilder.class_eval &block
      preferences_slot = bus["/redcar/preferences/#{plugin_scope}"]
      preferences_slot[name].attr_pref = true
      preferences_slot[name].attr_default = PreferenceBuilder.prefdef[:default]
      preferences_slot[name].attr_type = PreferenceBuilder.prefdef[:type]
      preferences_slot[name].attr_widget = PreferenceBuilder.prefdef[:widget]
      preferences_slot[name].attr_values = PreferenceBuilder.prefdef[:values]
      preferences_slot[name].attr_change = PreferenceBuilder.prefdef[:change_proc]
      preferences_slot[name].attr_bounds = PreferenceBuilder.prefdef[:bounds]
      preferences_slot[name].attr_step = PreferenceBuilder.prefdef[:step]
    end
    
    class << self
      attr_reader :prefdef
    end
    
    def self.clear
      @prefdef = {}
    end
    
    def self.type(val)
      @prefdef[:type] = val
    end

    def self.default(val)
      @prefdef[:default] = val
    end

    def self.widget(val=nil, &block)
      @prefdef[:widget] = (val || block)
    end

    def self.values(val=nil, &block)
      @prefdef[:values] = (val || block)
    end

    def self.change(&block)
      @prefdef[:change] = block
    end
    
    def self.bounds(val)
      @prefdef[:bounds] = val
    end
    
    def self.step(val)
      @prefdef[:step] = val
    end
  end
end
