# redcar/scripts/toolbar
# Adds the default toolbar to the application.
# D.B. Lucraft

# Redcar.toolbar.set_Redcar.toolbar_style(Gtk::Toolbar::BOTH)
Redcar.MainToolbar.append(:new, "New", "Open a blank tab.") do
  Redcar.command(:new)
end

Redcar.MainToolbar.append(:open, "Open", "Open a file in a new tab.") do
  Redcar.command(:open)
end

Redcar.MainToolbar.append(:save, "Save", "Save this tab.", 
                          :sensitize_to => :open_text_tabs?) do 
  Redcar.command(:save)
end

Redcar.MainToolbar.separator

Redcar.MainToolbar.append(:undo, "Undo", "Undo last command.", 
                          :sensitize_to => :undo_info?) do 
  Redcar.command(:undo)
end

Redcar.MainToolbar.separator

Redcar.MainToolbar.append(:cut, "Cut", "Cut the selected text to the clipboard.", 
                          :sensitize_to => :text_selected?) do
  Redcar.command(:cut)
end

Redcar.MainToolbar.append(:copy, "Copy", "Copy the selected text to the clipboard.", 
                          :sensitize_to => :text_selected?) do
  Redcar.command(:copy)
end

Redcar.MainToolbar.append(:paste, "Paste", "Paste the selected text to the clipboard.", 
                          :sensitize_to => :can_paste?) do
  Redcar.command(:paste)
end

# Redcar.MainToolbar.append(:paste, "Paste Alt", "Paste the selected text to the clipboard.", 
#                           :sensitize_to => :can_paste?) do
#   Redcar.command(:paste)
# end

Redcar.MainToolbar.append(:execute, "Debug", "Toggle debugging mode.") do
  Redcar.command(:toggle_debug_puts)
end
