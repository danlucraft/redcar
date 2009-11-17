require 'java'
require "plugins/application_swt/lib/application_swt/swt_wrapper"

class SwtExample
  def initialize
    Swt::Widgets::Display.set_app_name "Ruby SWT Test"

    @display = Swt::Widgets::Display.new
    @shell = Swt::Widgets::Shell.new(@display)
    @shell.setSize(450, 200)
    # 
    layout = Swt::Layout::FillLayout.new
    # layout.wrap = true
    # 
    @shell.setLayout layout
    @shell.setText "Ruby SWT Test"
    # 
    # label = Swt::Widgets::Label.new(@shell, Swt::SWT::CENTER)
    # label.setText "Ruby SWT Test"
    # 
    # Swt::Widgets::Button.new(@shell, Swt::SWT::PUSH).setText("Test Button 1")
    # 
    @shell.setMenuBar(create_menu_bar)
    
    # create_tab_folder
    create_sash_form
    
    create_key_listener
    
    @shell.pack
    @shell.open
  end
  
  def create_key_listener
    @display.add_filter(Swt::SWT::KeyDown) do |a|
      puts "type: #{a.type}, keyCode: #{a.keyCode}, character: #{a.character}, statemask: #{a.stateMask}"
    end
    @display.add_filter(Swt::SWT::KeyUp) do |a|
      puts "type: #{a.type}, keyCode: #{a.keyCode}, character: #{a.character}, statemask: #{a.stateMask}"
    end
  end
  
  def create_sash_form
    form = Swt::Custom::SashForm.new(@shell, Swt::SWT::VERTICAL)
  	form.setLayout(Swt::Layout::FillLayout.new)
  	child1 = Swt::Widgets::Composite.new(form, Swt::SWT::NONE)
  	child1.setLayout(Swt::Layout::FillLayout.new)
  	Swt::Widgets::Label.new(child1,Swt::SWT::NONE).setText("Label in pane 1")

  	child2 = Swt::Widgets::Composite.new(form, Swt::SWT::NONE)
  	child2.setLayout(Swt::Layout::FillLayout.new)
  	Swt::Widgets::Button.new(child2,Swt::SWT::PUSH).setText("Button in pane2")

  	child3 = Swt::Widgets::Composite.new(form, Swt::SWT::NONE)
  	child3.setLayout(Swt::Layout::FillLayout.new)
  	Swt::Widgets::Label.new(child3,Swt::SWT::PUSH).setText("Label in pane3")

  	form.setWeights([30,40,30].to_java(:int))
  	form.setSashWidth(10)
  end

  def create_tab_folder
    tabFolder = Swt::Custom::CTabFolder.new(@shell, Swt::SWT::BORDER + Swt::SWT::CLOSE)
  	3.times do |i|
  		tab_item = Swt::Custom::CTabItem.new(tabFolder, Swt::SWT::NONE)
  		tab_item.text = "TabItem " + i.to_s
  		button = Swt::Widgets::Button.new(tabFolder, Swt::SWT::PUSH)
  		button.setText("Page " + i.to_s)
  		tab_item.setControl(button)
		end
		tabFolder.pack
	end
  
  def create_menu_bar
    menuBar = Swt::Widgets::Menu.new(@shell, Swt::SWT::BAR)
    fileMenuHeader = Swt::Widgets::MenuItem.new(menuBar, Swt::SWT::CASCADE)
    fileMenuHeader.setText("&File")

    fileMenu = Swt::Widgets::Menu.new(@shell, Swt::SWT::DROP_DOWN)
    fileMenuHeader.setMenu(fileMenu)

    fileNewItem =  Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::PUSH)
    fileNewItem.setText("&New\tCtrl+N")
    fileNewItem.set_accelerator(Swt::SWT::CTRL + 'N'[0])

    fileOpenItem =  Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::PUSH)
    fileOpenItem.setText("&Open")
    fileOpenItem.set_accelerator(Swt::SWT::ALT + 'O'[0])

    fileSaveItem =  Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::PUSH)
    fileSaveItem.setText("&Save")
p Swt::SWT::CTRL + "N"[0]
    fileSaveItem.set_accelerator(Swt::SWT::CTRL + 'S'[0])

    fileSaveAsItem =  Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::PUSH)
    fileSaveAsItem.setText("&Save As")
    fileSaveAsItem.set_accelerator(Swt::SWT::COMMAND + 'A'[0])

    fileExitItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::PUSH)
    fileExitItem.setText("E&xit")
    fileExitItem.set_accelerator(Swt::SWT::MOD1 + 'Q'[0])

    helpMenuHeader = Swt::Widgets::MenuItem.new(menuBar, Swt::SWT::CASCADE)
    helpMenuHeader.setText("&Help")

    helpMenu = Swt::Widgets::Menu.new(@shell, Swt::SWT::DROP_DOWN)
    helpMenuHeader.setMenu(helpMenu)

    helpGetHelpItem = Swt::Widgets::MenuItem.new(helpMenu, Swt::SWT::CASCADE)
    helpGetHelpItem.setText("&Get Help")

    getHelpSubMenu = Swt::Widgets::Menu.new(@shell, Swt::SWT::DROP_DOWN)
    helpGetHelpItem.setMenu(getHelpSubMenu)
    
    gotoWebsiteItem = Swt::Widgets::MenuItem.new(getHelpSubMenu, Swt::SWT::PUSH)
    gotoWebsiteItem.setText("Goto Website")

    fileNewItem.addSelectionListener do
      puts "pressed File|New"
    end
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
  
  def start_checking_thread
    Thread.new do
      sleep 1
      check_menus
    end
  end
  
  def sync
    block = Swt::RRunnable.new do
      yield
    end
    @display.sync_exec(&block)
  end
  
  def check_menus
    sync do
      puts "Menus and Submenus (to one level)"
      @display.get_shells.first.get_menu_bar.get_items.to_a.each do |item|
        p item.get_text
        item.get_menu.get_items.to_a.each do |subitem|
          p "  " + subitem.get_text + " " + subitem.get_accelerator.to_s
        end
      end
    end
  end
end

app = SwtExample.new
app.start_checking_thread
app.start




