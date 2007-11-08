# redcar/scripts/toolbar
# Adds the default toolbar to the application.
# D.B. Lucraft

# # Redcar.toolbar.set_Redcar.toolbar_style(Gtk::Toolbar::BOTH)
# Redcar.MainToolbar.append(:icon => :new, 
#                           :text => "New", 
#                           :tooltip => "Open a blank tab.") do
#   Redcar.command(:new)
# end

# Redcar.MainToolbar.append(:icon => :open, 
#                           :text => "Open", 
#                           :tooltip => "Open a file in a new tab.") do
#   Redcar.command(:open)
# end

# Redcar.MainToolbar.append(:icon => :save, 
#                           :text => "Save", 
#                           :tooltip => "Save this tab.", 
#                           :sensitize_to => :open_text_tabs?) do 
#   Redcar.command(:save)
# end

# Redcar.MainToolbar.separator

# Redcar.MainToolbar.append(:icon => :undo, 
#                           :text => "Undo", 
#                           :tooltip => "Undo last command.", 
#                           :sensitize_to => :undo_info?) do 
#   Redcar.command(:undo)
# end

# Redcar.MainToolbar.separator

# Redcar.MainToolbar.append(:icon => :cut,  
#                           :text => "Cut", 
#                           :tooltip => "Cut the selected text to the clipboard.", 
#                           :sensitize_to => :text_selected?) do
#   Redcar.command(:cut)
# end

# Redcar.MainToolbar.append(:icon => :copy,  
#                           :text => "Copy", 
#                           :tooltip => "Copy the selected text to the clipboard.", 
#                           :sensitize_to => :text_selected?) do
#   Redcar.command(:copy)
# end

# Redcar.MainToolbar.append(:icon => :paste,  
#                           :text => "Paste", 
#                           :tooltip => "Paste the selected text to the clipboard.", 
#                           :sensitize_to => :can_paste?) do
#   Redcar.command(:paste)
# end

# # Redcar.MainToolbar.append(:paste, "Paste Alt", "Paste the selected text to the clipboard.", 
# #                           :sensitize_to => :can_paste?) do
# #   Redcar.command(:paste)
# # end
