
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
      if @preferences[plugin_name]
        @preferences[plugin_name] = 
          @preferences[plugin_name].merge(builder.prefs)
      else
        @preferences[plugin_name] = builder.prefs
      end
      @preferences[plugin_name].each do |pref_name, pref_hash|
        path =  "preferences/"+plugin_name.gsub(" ", "-")+"/"
        Redcar[path+pref_name.gsub(" ", "-")+"/type"] ||= pref_hash[:type].to_s
        Redcar[path+pref_name.gsub(" ", "-")+"/value"] ||= pref_hash[:default].to_s
      end
    end
    
    def self.plugin_names
      @preferences.keys
    end
    
    def self.preferences
      @preferences ||= {}
    end
    
    class PreferencesBuilder
      attr_reader :prefs
      def initialize
        @prefs = {}
      end
      
      def add(name, options)
        options = process_params(options,
                                 { :type => :MANDATORY,
                                   :default => "" ,
                                   :values => [],
                                   :min => nil,
                                   :max => nil,
                                   :step => nil,
                                   :if_changed => nil
                                 })
        @prefs[name] = options
      end
      
      def add_with_widget(name, options)
        options = process_params(options,
                                 { :widget => :MANDATORY,
                                   :default => "",
                                   :if_changed => nil
                                 })
        @prefs[name] = options
      end
    end
    
    class Preferences
      def initialize(plugin_name)
        @plugin_name = plugin_name.gsub(" ", "-")
        @path =  "preferences/"+@plugin_name+"/"
      end
      
      def [](n)
        Redcar[@path+n.gsub(" ", "-")+"/value"]
      end
      
      def []=(n, v)
        Redcar[@path+n.gsub(" ", "-")+"/value"] = v
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
      @dialog = @glade["dialog_preferences"]
      @preferences = Redcar::Preferences.preferences
      @sw = @glade["list_sw"]
      @list = Redcar::GUI::List.new
      @sw.add(@list.treeview)
      @plugin_names = Redcar::Preferences.plugin_names
      @initial_values = {}
      @on_change = {}
      build_list
      @list.treeview.show_all
      @frame = @glade["frame_options"]
      build_widgets(@plugin_names[0])
      @list.select(0)
      @list.on_single_click do |row|
        build_widgets(row)
      end
      @lazy_apply = []
    end
    
    def on_ok
      if @current_plugin_name
        save_values
      end
      @lazy_apply.each {|p| p.call}
      puts :applied_changes
      @dialog.destroy
      puts :destroyed
    end
    
    def on_cancel
      @dialog.destroy
    end
    
    def build_list
      @list.replace(@plugin_names)
    end
    
    def save_values
      prefs = Redcar::Preferences::Preferences.new(@current_plugin_name)
      plugin_name = @current_plugin_name
      @widgets.each do |pref_name, widget|
        val = widget.preference_value
        @lazy_apply << fn { 
          prefs[pref_name] = val  
          if @initial_values[plugin_name+"/"+pref_name] and 
              @initial_values[plugin_name+"/"+pref_name] != val and
              @on_change[plugin_name+"/"+pref_name] != nil
            @on_change[plugin_name+"/"+pref_name].call
          end
        }
      end
    end
    
    def build_widgets(plugin_name)
      if @current_plugin_name
        save_values
      end
      @current_plugin_name = plugin_name
      plugin_prefs = @preferences[plugin_name]
      pref_values = Redcar::Preferences::Preferences.new(plugin_name)
      vbox = Gtk::VBox.new
      @widgets = {}
      plugin_prefs.each do |pref_name, pref_hash|
        if pref_hash[:widget]
          label = Gtk::Label.new(pref_name)
          widget = pref_hash[:widget].call
        else
          case pref_hash[:type]
          when :string
            label = Gtk::Label.new(pref_name)
            widget = Gtk::Entry.new
            widget.text = pref_values[pref_name]
            def widget.preference_value
              self.text
            end
          when :integer
            label = Gtk::Label.new(pref_name)
            if pref_hash[:min] and pref_hash[:max]
              widget = Gtk::SpinButton.new(pref_hash[:min].to_f, 
                                           pref_hash[:max].to_f,
                                           (pref_hash[:step]||1).to_f)
            else
              widget = Gtk::SpinButton.new
            end
            widget.value = pref_values[pref_name]
            def widget.preference_value
              self.value.to_s
            end
          when :combo
            label = Gtk::Label.new(pref_name)
            widget = Gtk::ComboBox.new
            if pref_hash[:values].is_a? Array
              values = pref_hash[:values]
            elsif pref_hash[:values].is_a? Proc
              values = pref_hash[:values].call
            end
            values.each do |entry|
              widget.append_text(entry)
            end
            widget.active = values.index(pref_values[pref_name])
            def widget.preference_value
              self.active_text
            end
          when :toggle
            label = nil
            widget = Gtk::CheckButton.new(pref_name)
            widget.active = (pref_values[pref_name] == "true")
            def widget.preference_value
              self.active?.to_s
            end
          end
        end
        hbox = Gtk::HBox.new
        hbox.pack_start(label) if label
        hbox.pack_start(widget)
        vbox.pack_start(hbox, false)
        hbox.show_all
        @widgets[pref_name] = widget
        @initial_values[plugin_name+"/"+pref_name] = widget.preference_value
        @on_change[plugin_name+"/"+pref_name] = pref_hash[:if_changed]
      end
      @frame.children.each {|child| @frame.remove(child)}
      @frame.add(vbox)
      vbox.show
    end
  end
end
