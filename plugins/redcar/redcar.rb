
module Redcar
  module Top
    class NewCommand < Command
      key "Cmd+N"
      
      def execute
        puts "making a new document"
        tab = win.new_tab(Redcar::EditTab)
        tab.focus
      end
    end
    
    class FileOpenCommand < Command
      key "Cmd+O"
    
      def execute
        p :open
        dialog = Swt::Widgets::FileDialog.new(win.controller.shell, Swt::SWT::OPEN)
        dialog.set_filter_path("/home/danlucraft/")
        puts "save to : " + dialog.open.to_s
      end
    end
    
    class PrintContents < Command
      key "Cmd+P"
      
      def execute
        puts "printing contents"
        tab = win.notebook.tabs.first
        p tab.edit_view.document.to_s
      end
    end
    
    class SetContents < Command
      key "Cmd+S"
      
      def execute
        puts "setting contents"
        tab = win.notebook.tabs.first
        tab.edit_view.document.text = "class Redcar\n  include JRuby\nend\n"
      end
    end
    
    class PrintHistoryCommand < Command
      def execute
        Redcar.history.each do |c|
          puts c
        end
      end
    end
    
    def self.start
      Redcar.gui = ApplicationSWT.gui
      Redcar.app.controller = ApplicationSWT.new(Redcar.app)
      builder = Menu::Builder.new do
        sub_menu "File" do
          item "New", NewCommand
          item "Open", FileOpenCommand
        end
        sub_menu "Debug" do
          item "Print Command History", PrintHistoryCommand
          item "Print Contents", PrintContents
          item "Set Contents", SetContents
        end
        sub_menu "Help" do
          item "Website", PrintHistoryCommand
        end
      end
      
      Redcar.app.menu = builder.menu
      Redcar.app.new_window
    end
  end
end