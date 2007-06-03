
Redcar.menu("_File") do |menu|
  menu.command("_New", :new, :file, "control n") do |pane, tab|
    new_tab = Redcar.new_tab
    new_tab.focus
    Redcar.StatusBar.main = "New document"
  end
  
  menu.command("_Open", :open, :open, "ctrl o") do |pane, tab|
    new_tab = Redcar.new_tab
    if new_tab.filename = Redcar::Dialog.open and File.file?(new_tab.filename)
      puts "loading file #{new_tab.filename}"
      new_tab.load
      new_tab.name = new_tab.filename.split(/\//).last
      new_tab.focus
      new_tab.cursor = 0
    end
  end
  
  menu.command("Open _Project", :open_project, :open, "ctrl p") do
    if dirname = Redcar::Dialog.open_folder
      puts "opening project #{dirname}"
      Redcar::Project.add_directory(dirname.split(/\//).last, dirname)
      Redcar.project_sw.show
    end
  end
  
  menu.separator
  
  menu.command("_Save", :save, :save, "ctrl s", :sensitive => :tabs) do |pane, tab|
    puts "saving file #{tab.filename}"
    if tab.filename
      puts :has_filename
      tab.save
    elsif tab.filename = Redcar::Dialog.save
      puts :does_not_have_filename
      tab.name = tab.filename.split(/\//).last
      tab.save
    end
  end
  
  menu.command("Save _As", :save_as, :save_as, "ctrl-alt s", :sensitive => :tabs) do |pane, tab|
    puts "saving file #{tab.filename}"
    if tab.filename = Redcar::Dialog.save
      tab.name = tab.filename.split(/\//).last
      tab.save
    end
  end
  
  menu.separator
  
  menu.command("_Close", :close, :close, "ctrl w", :sensitive => :tabs) do |pane, tab|
    tab.close if tab
  end
  
  menu.command("_Exit", :exit,  :quit, "ctrl alt q") do
    Redcar.quit
  end
end
