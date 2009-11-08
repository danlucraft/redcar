module SwtHelper
  def main_menu
    display = Redcar::ApplicationSWT.display
    shell   = display.get_shells.to_a.first
    menu_bar = shell.get_menu_bar
    menu_bar
  end
  
  def first_shell
    Redcar::ApplicationSWT.display.get_shells.to_a.first
  end
end
    
class FakeDialogAdapter
  def initialize
    @responses = {}
  end
  
  def set(method, value)
    @responses[method] = value
  end
  
  def open_file(*args)
    @responses[:open_file]
  end
end

World(SwtHelper)