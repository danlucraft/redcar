module SwtHelper
  def main_menu
    display = Redcar::ApplicationSWT.display
    shell   = display.get_active_shell
    menu_bar = shell.get_menu_bar
    menu_bar
  end
end

World(SwtHelper)