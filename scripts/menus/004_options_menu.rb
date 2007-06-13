
Redcar.menu("_Options") do |menu|
  menu.command("Change _Font", :change_font, :select_font, "") do
    dialog = Gtk::FontSelectionDialog.new("Select Application Font")
    dialog.font_name = Redcar["texttab/font"]
    dialog.preview_text = "Redcar is for Ruby"
    if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
      puts fn = dialog.font_name
    end
    fn = dialog.font_name
    dialog.destroy
    Redcar["texttab/font"] = fn
    Redcar.current_window.all_tabs.each do |tab|
      tab.set_font(fn)
    end
  end
  
  menu.command("Preferences...", :edit_menus, nil, nil) do
    dialog = Redcar::PreferencesDialog.new
    dialog.run
  end

  menu.command("Edit Menus...", :edit_menus, nil, nil) do
    dialog = Redcar::MenuEditDialog.new
    dialog.run
  end
end
