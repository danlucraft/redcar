module Redcar
  # This class is your plugin. Try adding new commands in here
  # and putting them in the menus.
  class MyPlugin
  
    # This method is run as Redcar is booting up.
    def self.menus
      # Here's how the plugin menus are drawn. Try adding more
      # items or sub_menus.
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "My Plugin", :priority => 139 do
            item "Hello World!", HelloWorldCommand
            item "Edit My Plugin", EditMyPluginCommand
          end
        end
      end
    end

    # Example command: showing a dialog box.
    class HelloWorldCommand < Redcar::Command
      def execute
        Application::Dialog.message_box("Hello World!")
      end
    end

    # Command to open a new window, make the project my_plugin
    # and open this file.
    class EditMyPluginCommand < Redcar::Command
      def execute
        # Open the project in a new window
        Project::Manager.open_project_for_path("plugins/my_plugin")
        
        # Create a new edittab
        tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
        
        # A FileMirror's job is to wrap up the file in an interface that the Document understands.
        mirror = Project::FileMirror.new(File.join(Redcar.root, "plugins", "my_plugin", "lib", "my_plugin.rb"))
        tab.edit_view.document.mirror = mirror

        # Make sure the tab is focussed and the user can't undo the insertion of the document text
        tab.edit_view.reset_undo
        tab.focus
      end
    end
  end
end