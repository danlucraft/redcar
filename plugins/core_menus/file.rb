
module Redcar::Plugins::CoreMenus
  module FileMenu
    extend Redcar::CommandBuilder
    extend Redcar::MenuBuilder
    
    command "Core/File/New" do |c|
      c.menu = "File/New"
      c.icon = :FILE
      c.keybinding = "super n"
      c.command %q{
        new_tab = Redcar.new_tab
        new_tab.focus
        Redcar.StatusBar.main = "New document"
      }
    end
    
    command "Core/File/Open" do |c|
      c.menu = "File/Open"
      c.icon = :OPEN
      c.keybinding = "super o"
      c.command %q{
        if filename = Redcar::Dialog.open and File.file?(filename)
          new_tab = Redcar.new_tab
          new_tab.filename = filename
          puts "loading file #{new_tab.filename}"
          new_tab.load
          new_tab.name = new_tab.filename.split(/\//).last
          new_tab.focus
          new_tab.cursor = 0
        end
      }
    end
    
    menu_separator "File"
    
    command "Core/File/Save" do |c|
      c.menu = "File/Save"
      c.icon = :SAVE
      c.keybinding = "super s"
      c.sensitive = :unsaved_text_tabs?
      c.command %q{
        puts "saving file #{tab.filename}"
        if tab.filename
          puts :has_filename
          tab.save
        elsif tab.filename = Redcar::Dialog.save
          puts :does_not_have_filename
          tab.name = tab.filename.split(/\//).last
          tab.save
        end
      }
    end
    
    command "Core/File/Save As" do |c|
      c.menu = "File/Save As"
      c.icon = :SAVE_AS
      c.keybinding = "alt-super s"
      c.sensitive = :unsaved_text_tabs?
      c.command %q{
        puts "saving file #{tab.filename}"
        if tab.filename = Redcar::Dialog.save
          tab.name = tab.filename.split(/\//).last
          tab.save
        end
      }
    end
    
    menu_separator "File"
    
    command "Core/File/Close Tab" do |c|
      c.menu = "File/Close"
      c.icon = :CLOSE
      c.command %q{ tab.close }
      c.keybinding = "super w"
      c.sensitive = :open_tabs?
    end
    
    command "Core/File/Quit" do |c|
      c.menu = "File/Exit"
      c.keybinding = "alt F4"
      c.icon = :CLOSE
      c.command = %q{ Redcar.quit }
    end
  end
end
