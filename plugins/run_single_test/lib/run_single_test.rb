module Redcar
  # This class is your plugin. Try adding new commands in here
  # and putting them in the menus.
  class RunSingleTest
  
    # This method is run as Redcar is booting up.
    def self.menus
      # Here's how the plugin menus are drawn. Try adding more
      # items or sub_menus.
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Run Single Test", :priority => 139 do
            item "Run Single Test", RunSingleTestCommand
          end
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+Shift+T", RunSingleTestCommand
      end
      [osx]
    end
    
    class RunSingleTestCommand < Redcar::Command
      TEST_PATTERNS = [/should\s+\"(.*)\"/, /context\s+\"(.*)\"/, /def\s+(test_.*)\s+/]
      def execute
        doc = Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document
        current_line = doc.get_line(doc.cursor_line)      
        TEST_PATTERNS.each do |pattern|
          if current_line =~ pattern
            Redcar::Runnables.run_process Project::Manager.focussed_project.path, %{ruby -Itest #{doc.path} -n "/#{$1}/"}, "Running single test"
            return
          end
        end
        Redcar::Runnables.run_process Project::Manager.focussed_project.path, %{ruby -Itest #{doc.path}}, "Running single test"
      end
    end
    
  end
end