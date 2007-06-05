
module Redcar
  class Toolbar
    class Main
      def self.toolbar_widget=(gtk_toolbar)
        @@gtk_toolbar = gtk_toolbar
      end
      
      def self.toolbar_widget
        @@gtk_toolbar
      end
      
      def self.append(options={}, &block)
        options = process_params(options,
                                 { :icon => :MANDATORY,
                                   :tooltip => "",
                                   :sensitize_to => nil,
                                   :text => ""
                                 })
        gtk_tb = @@gtk_toolbar.append(Redcar::Icon.get(options[:icon]), options[:tooltip]) do
          block.call(Redcar.current_pane, Redcar.current_tab)
        end
        if options[:sensitize_to]
          gtk_tb.sensitize_to options[:sensitize_to]
        end
      end
      
      def self.append_combo(list, &block)
        # true sets the combobox to be text only...
        gtk_combo_box = Gtk::ComboBox.new(true)
        list.each {|item| gtk_combo_box.append_text(item) }
        gtk_combo_box.signal_connect("changed") do |gtk_combo_box1|
          block.call(Redcar.current_pane, 
                     Redcar.current_tab,
                     gtk_combo_box1.active_text)
        end
        @@gtk_toolbar.append(gtk_combo_box)
        gtk_combo_box.show
      end
      
      def self.separator
        @@gtk_toolbar.append_space
      end
    end
  end
end

module Redcar
  def self.MainToolbar
    Redcar::Toolbar::Main
  end
end
