
module Redcar
  module Plugins
    module PluginManager
      extend FreeBASE::StandardPlugin
    end
  end
  
  class PluginTab < Tab
    def initialize(pane)
      @ts = Gtk::ListStore.new(String, String)
      @tv = Gtk::TreeView.new(@ts)
      renderer = Gtk::CellRendererText.new
      col1 = Gtk::TreeViewColumn.new("Name", renderer, :text => 0)
      col2 = Gtk::TreeViewColumn.new("State", renderer, :text => 1)
      @tv.append_column(col1)
      @tv.append_column(col2)
      @tv.show
      super(pane, @tv, :scrolled => true)
      build_tree
      build_menu
      @tv.signal_connect("button_press_event") do |_, event|
        if (event.button == 3)
          @menu.popup(nil, nil, event.button, event.time)
        end
      end
    end
    
    def build_menu
      @menu = Gtk::Menu.new
      item_reload = Gtk::MenuItem.new("Reload")
      item_info   = Gtk::MenuItem.new("Info")
      @menu.append(item_reload)
      @menu.append(item_info)
      @menu.show_all
      
      item_info.signal_connect("activate") do
        slot = $BUS['/plugins/'+@tv.selection.selected[0]]
        string =<<END
Name: #{slot.name}
Version: #{slot['info/version'].data}
Author: #{slot['info/author'].data}
Description: #{slot['info/description'].data}
END
        dialog = Gtk::MessageDialog.new(Redcar.current_window, 
                                        Gtk::Dialog::DESTROY_WITH_PARENT,
                                        Gtk::MessageDialog::INFO,
                                        Gtk::MessageDialog::BUTTONS_CLOSE,
                                        string)
        dialog.title = "Plugin Information"
        dialog.run
        dialog.destroy
      end
      
      item_reload.signal_connect("activate") do
        $BUS['/plugins/'+@tv.selection.selected[0]+"/reload"].call
      end
    end

    def build_tree
      plugins_slot = $BUS['/plugins']
      plugins_slot.each_slot do |plugin_slot|
        iter = @ts.append
        @ts.set_value(iter, 0, plugin_slot.name)
        @ts.set_value(iter, 1, plugin_slot['state'].data.to_s.downcase)
      end
    end
  end
end
