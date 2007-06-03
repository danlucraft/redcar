
Redcar.menu("_Options") do |menu|
  menu.command("Change _Font", :change_font, :select_font, "") do
    dialog = Gtk::FontSelectionDialog.new("Select Application Font")
    dialog.font_name = "Monospace 12"
    dialog.preview_text = "Redcar is for Ruby"
    if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
      puts fn = dialog.font_name
    end
    fn = dialog.font_name
    dialog.destroy
    Redcar.tabs.current.set_font(fn)
  end
end
