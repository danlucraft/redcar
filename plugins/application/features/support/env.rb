module SwtHelper
  def main_menu
    display = Redcar::ApplicationSWT.display
    p display
    p display.get_shells.to_a
    shell   = display.get_shells.to_a.first
    menu_bar = shell.get_menu_bar
    menu_bar
  end
end

World(SwtHelper)