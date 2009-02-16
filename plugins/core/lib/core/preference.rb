
module Redcar
  # This module controls the declaration and retrieval of new 
  # user preferences. The preference is declared with a name 
  # and a default and stored as a String. Also there are metadata 
  # that the official Redcar plugin "Preferences Editor" uses to 
  # create a gui for the user to set these preferences. 
  #
  # Plugin authors should try to declare the preference as
  # fully as possible so that the Preferences dialog can be
  # automatically populated with the appropriate options.
  #
  # === Examples
  #
  # Preferences can be defined from within Redcar::Plugins. Here is 
  # a minimal example: 
  #  
  #  class MyPlugin < Redcar::Plugin
  #    preference "Editing/Wrap words" do
  #      default true
  #    end
  #  end
  #
  # NB. The name of a preference must contain a forward slash.
  # 
  # Getter and setter methods are provided:
  #
  #   value = Redcar::Preference.get("Editing/Wrap words").to_bool
  #   Redcar::Preference.set("Editing/Wrap words", false)
  #
  # (The preferences are converted to strings when they are saved, 
  # so the value returned by 'get' is the string "false". Object#to_bool
  # is a helper method that converts such strings to booleans.)
  #
  # A more useful preference definition (this is a real preference
  # and can be found in plugins/core/standard_menus.rb:
  # 
  #   class MyPlugin < Redcar::Plugin
  #     preference "Editing/Show line numbers" do
  #       default true
  #       type    :toggle
  #       change do
  #         value = Redcar::Preference.get("Editing/Show line numbers").to_bool
  #         win.collect_tabs(EditTab).each do |tab| 
  #           tab.view.show_line_numbers = value.to_bool
  #         end
  #       end
  #     end
  #   end
  #
  # The preference is defined with a default as before. Additionally the 
  # type of the preference is set as :toggle, therefore the Preferences Editor
  # will create a checkbox to represent it in the Dialog. The block passed to 
  # change is called by the Dialog if the user changes the value of the 
  # preferences. 
  #
  # See the Redcar::PreferenceBuilder for all methods that are valid
  # within the preference definition block.
  module Preference
    def self.load #:nodoc:
      FreeBASE::Properties.new("Redcar Preferences", 
                               Redcar::VERSION, 
                               bus('/redcar/preferences'), 
                               App.home_dot_dir + "/preferences.yaml")
                            end
    
    # Get the value of the preference with the given name. Always 
    # returns a String.
    def self.get(name)
      if bus("/redcar/preferences/#{name}/", true)
        slot = bus("/redcar/preferences/#{name}")
        slot.data == nil ? slot.attr_default : slot.data
      else
        raise "unknown preference: #{name}"
      end
    end
    
    # Set the value of a preference with the given name.
    def self.set(name, value)
      if slot = bus("/redcar/preferences/#{name}", true)
        slot.data = value
      else
        raise "unknown preference: #{name}"
      end
    end
  end
  
  # See Redcar::Preference for examples of how to use this module.
  module PreferenceBuilder
    def preference(name, &block)
      unless name.include?("/")
        raise "Trying to set global preference: /redcar/preferences/#{name}"
      end
      PreferenceBuilder.clear
      PreferenceBuilder.class_eval &block
      preferences_slot = bus["/redcar/preferences/"]
      if preferences_slot[name].data == nil
        preferences_slot[name].data = PreferenceBuilder.prefdef[:default]
      end
      preferences_slot[name].attr_pref = true
      preferences_slot[name].attr_default = PreferenceBuilder.prefdef[:default]
      preferences_slot[name].attr_type = PreferenceBuilder.prefdef[:type]
      preferences_slot[name].attr_widget = PreferenceBuilder.prefdef[:widget]
      preferences_slot[name].attr_values = PreferenceBuilder.prefdef[:values]
      preferences_slot[name].attr_change = PreferenceBuilder.prefdef[:change]
      preferences_slot[name].attr_bounds = PreferenceBuilder.prefdef[:bounds]
      preferences_slot[name].attr_step = PreferenceBuilder.prefdef[:step]
    end
    
    class << self
      attr_reader :prefdef
    end
    
    def self.clear #:nodoc:
      @prefdef = {}
    end
    
    # Sets the type of the preference. Currently may be one of:
    # 
    #   :toggle
    #   :string
    #   :combo      use values to populate list
    #   :integer    use bounds and step
    # 
    # This and widget are mutually exclusive. 
    def self.type(val)
      @prefdef[:type] = val
    end

    # Sets the default value of the preference.
    def self.default(val)
      @prefdef[:default] = val
    end

    # Use to create the widget to be used in the Preferences Dialog.
    # 
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
