
module Redcar
  module Top
    def self.start
      Redcar.gui.controller_for(Redcar.app)
      Redcar.app.new_window
      menu = Redcar::Application::Menu.new
      menu << Redcar::Application::Menu.new("File") 
      menu << Redcar::Application::Menu.new("Help")
      Redcar.app.menu = menu
    end
  end
end