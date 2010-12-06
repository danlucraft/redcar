module Redcar
  class CloseTabs < Redcar::Command
    def self.menus
      Menu::Builder.build do
        sub_menu "File" do
          item "Close Others", :command => CloseOthers, :priority => 99
          item "Close All", :command => CloseAll, :priority => 100
        end
      end
    end
  end
  
  class CloseAll < Redcar::Command
    def execute
      window = Redcar.app.focussed_window
      tabs = window.all_tabs
      tabs.each do |t|
        Redcar::Top::CloseTabCommand.new(t).run
      end
    end
  end
  
  class CloseOthers < Redcar::Command
    def execute
      window = Redcar.app.focussed_window
      current_tab = Redcar.app.focussed_notebook_tab
      tabs = window.all_tabs
      tabs.each do |t|
        unless t == current_tab
          Redcar::Top::CloseTabCommand.new(t).run
        end
      end
    end
  end

end