
module Redcar
  module Top
    def self.start
      Redcar.gui = Redcar::ApplicationSWT.gui
      @app_controller = Redcar::ApplicationSWT.new(Redcar.app)
      menu = Redcar::Application::Menu.new
      file_menu = Redcar::Application::Menu.new("File") 
      menu << file_menu
      menu << Redcar::Application::Menu.new("Help")
      file_menu << Redcar::Application::MenuItem.new("New", :Comasd)
      Redcar.app.menu = menu
      Redcar.app.new_window
    end
  end
end