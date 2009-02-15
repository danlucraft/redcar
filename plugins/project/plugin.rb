
module Redcar
  class ProjectPlugin < Redcar::Plugin
    class << self
      attr_accessor :tab
    end
        
    on_load do
      Sensitive.register(:open_project, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab]) do
        Redcar.win and Redcar.win.tabs.map(&:class).include?(ProjectTab)
      end
      Kernel.load File.dirname(__FILE__) + "/commands/open_project.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/find_file_command.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/add_directory_to_project_command.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/remove_directory_from_project_command.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/new_file_in_project_command.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/rename_path_in_project_command.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/delete_path_in_project_command.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/new_directory_in_project_command.rb"
      Kernel.load File.dirname(__FILE__) + "/tabs/project_tab.rb"
      Kernel.load File.dirname(__FILE__) + "/dialogs/find_file_dialog.rb"
    end
    
    on_start do
      Hook.attach(:redcar_start) do
        files, directories = [], []
        Redcar::App.ARGV.each do |arg|
          if File.exist?(arg)
            if File.file?(arg)
              files << File.expand_path(arg)
            elsif File.directory?(arg)
              directories << File.expand_path(arg)
            end
          end
        end
        if directories.any?
          Redcar::SplitHorizontal.new.do
          tab = Redcar::OpenProject.new.do
          directories.each do |dir|
            tab.add_directory(dir.split("/").last, dir)
          end
        end
        if files.any?
          files.each do |fn|
            Redcar::OpenTab.new(fn).do
          end
        end
      end
    end
  end
end
