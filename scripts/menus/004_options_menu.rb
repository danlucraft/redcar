
Redcar.menu("_Options") do |menu|
  menu.command("Preferences...", :edit_menus, :preferences, nil) do
    dialog = Redcar::PreferencesDialog.new
  end

  menu.command("Edit Menus...", :edit_menus, :preferences, nil) do
    dialog = Redcar::MenuEditDialog.new
  end
end
