module SwtHelper
  def main_menu
    display = Redcar::ApplicationSWT.display
    shell   = display.get_shells.first
    menu_bar = shell.get_menu_bar
    menu_bar
  end
end

World(SwtHelper)