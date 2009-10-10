
module Redcar
  module Top
    class NewCommand < Command
      def execute
        puts "making a new document"
      end
    end
    
    class WebsiteCommand < Command
      def execute
        puts "go to website: redcareditor.com"
      end
    end
    
    def self.start
      Redcar.gui = ApplicationSWT.gui
      @app_controller = ApplicationSWT.new(Redcar.app)
      builder = Menu::Builder.new do
        sub_menu "File" do
          item "New", NewCommand
        end
        sub_menu "Help" do
          item "Website", WebsiteCommand
        end
      end
      
      Redcar.app.menu = builder.menu
      Redcar.app.new_window
    end
  end
end