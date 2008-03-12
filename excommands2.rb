
module Com::RedcarIDE
  class FooTab < Tab
    include Redcar::Plugin
    
    instance_command
    key "Ctrl+W"
    def close
      p :closing_footab
    end
    
    instance_command
    key :snippet, "Tab"
    def insert_snippet
      puts "inserting snippet"
    end
    
    menu "Tools" do
      item "Show Name", "Ctrl+W", :PREFERENCES do
        puts FooTab.name
      end
      
      item "Open FooTab", "Ctrl+O"
    end
  end
end


class Redcar::Window
  instance_command :key => "Ctrl+O"
  def open_footab
    p :open_footab
  end
end
