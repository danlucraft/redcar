
module Redcar
  class ProjectPlugin < Redcar::Plugin
    on_load do
      Sensitive.register(:open_project, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab]) do
        Redcar.win and Redcar.win.tabs.map(&:class).include?(ProjectTab)
      end

      Kernel.load File.dirname(__FILE__) + "/commands/open_project.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/find_file_command.rb"
      Kernel.load File.dirname(__FILE__) + "/tabs/project_tab.rb"
      Kernel.load File.dirname(__FILE__) + "/dialogs/find_file_dialog.rb"
    end
  end
end
