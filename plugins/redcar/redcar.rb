
module Redcar
  module Top
    def self.start
      Redcar.gui = ApplicationSWT.gui
      @app_controller = ApplicationSWT.new(Redcar.app)
      builder = Menu::Builder.new do
        sub_menu "File" do
          item "New", :NewCommand
        end
        sub_menu "Help" do
          item "Foo", :FooCommand
        end
      end
      
      Redcar.app.menu = builder.menu
      Redcar.app.new_window
    end
  end
end