module Redcar
  class PasteHistory < Redcar::EditTabCommand
    key  "Ctrl+Alt+V"
    icon :PASTE
    
    def execute
      if(Redcar::App.paste_history != nil)
        paste_hist = Gtk::Menu.new

        Redcar::App.paste_history.reverse_each{|p|
          paste_item = Gtk::MenuItem.new(p)
          size = paste_item.size_request
          paste_item.set_size_request(300, size[1])
          paste_item.signal_connect('activate') { |m| paste_item_selected(m) }
          paste_hist.append(paste_item)
        }       
        paste_hist.show_all

        paste_hist.popup(nil,nil,0,0) do |_, x, y, _| [x, y]
          win = Redcar::App.focussed_window
          tab = win.focussed_tab
          tv = tab.view
          gdk_rect = tv.get_iter_location(tab.document.cursor_iter)
          x = gdk_rect.x+gdk_rect.width
          y = gdk_rect.y+gdk_rect.height
          winx, winy = Redcar.win.position
          _, mh = paste_hist.size_request
          tv.buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, x+winx, y+winy+mh+30)
        end
      end
    end
  
    def paste_item_selected(menu_item)
      str = menu_item.child.text
      n = str.scan("\n").length+1
      l = doc.cursor_line
      doc.delete_selection
      doc.insert_at_cursor(str)
      if n > 1 and Redcar::Preference.get("Editing/Indent pasted text").to_bool
        n.times do |i|
          tab.view.indent_line(l+i)
        end
      end
    end    
  end
end
