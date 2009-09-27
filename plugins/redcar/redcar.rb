
module Redcar
  module Top
    def self.start
      Redcar.gui = Redcar::ApplicationSWT.gui
      @app_controller = Redcar::ApplicationSWT.new(Redcar.app)
      menu = Redcar::Application::Menu.new
      menu << Redcar::Application::Menu.new("File") 
      menu << Redcar::Application::Menu.new("Help")
      Redcar.app.menu = menu
      Redcar.app.new_window
    end
  end
end