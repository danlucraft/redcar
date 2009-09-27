require 'java'
require "plugins/application_swt/lib/application_swt/swt_wrapper"

class SwtExample
  def initialize
    Swt::Widgets::Display.set_app_name "Ruby SWT Test"

    @display = Swt::Widgets::Display.new
    @shell = Swt::Widgets::Shell.new(@display)
    @shell.setSize(450, 200)

    layout = Swt::Layout::RowLayout.new
    layout.wrap = true

    @shell.setLayout layout
    @shell.setText "Ruby SWT Test"

    label = Swt::Widgets::Label.new(@shell, Swt::SWT::CENTER)
    label.setText "Ruby SWT Test"
    
    Swt::Widgets::Button.new(@shell, Swt::SWT::PUSH).setText("Test Button 1")
    
    @shell.setMenuBar(create_menu_bar)
    @shell.pack
    @shell.open
  end
  
  def create_menu_bar
    menuBar = Swt::Widgets::Menu.new(@shell, Swt::SWT::BAR)
    fileMenuHeader = Swt::Widgets::MenuItem.new(menuBar, Swt::SWT::CASCADE)
    fileMenuHeader.setText("&File")

    fileMenu = Swt::Widgets::Menu.new(@shell, Swt::SWT::DROP_DOWN)
    fileMenuHeader.setMenu(fileMenu)

    fileSaveItem =  Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::PUSH)
    fileSaveItem.setText("&Save")

    fileExitItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::PUSH)
    fileExitItem.setText("E&xit")

    helpMenuHeader = Swt::Widgets::MenuItem.new(menuBar, Swt::SWT::CASCADE)
    helpMenuHeader.setText("&Help")

    helpMenu = Swt::Widgets::Menu.new(@shell, Swt::SWT::DROP_DOWN)
    helpMenuHeader.setMenu(helpMenu)

    helpGetHelpItem = Swt::Widgets::MenuItem.new(helpMenu, Swt::SWT::PUSH)
    helpGetHelpItem.setText("&Get Help")

    fileExitItem.addSelectionListener do
      puts "pressed File|Exit"
    end
    fileSaveItem.addSelectionListener do
      puts "pressed File|Save"
    end
    helpGetHelpItem.addSelectionListener do
      puts "pressed Help|Get Help"
    end
    menuBar
  end
  
  def start
    while (!@shell.isDisposed) do
      @display.sleep unless @display.readAndDispatch
    end

    @display.dispose
  end
end

app = SwtExample.new
app.start




