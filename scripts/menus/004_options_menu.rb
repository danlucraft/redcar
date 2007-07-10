
Redcar.menu("_Options") do |menu|
  menu.command("Preferences...", :edit_menus, :preferences, nil) do
    dialog = Redcar::PreferencesDialog.new
  end

  menu.command("Edit Menus...", :edit_menus, :preferences, nil) do
    dialog = Redcar::MenuEditDialog.new
  end
  
  menu.command("Edit Menus... (tab)", :edit_menus_tab, :preferences, nil) do
    nt = Redcar.new_tab(Redcar::MenuEditTab)
    nt.name = "Edit Menus"
    nt.focus
  end
end
