
module Redcar::Plugins::CoreMenus
  class PanesMenu
    extend Redcar::CommandBuilder
    extend Redcar::MenuBuilder
    extend Redcar::ContextMenuBuilder
    extend Redcar::CommandBuilder
    
    context_menu_separator "Panes"
    
    command "Panes/Alignment/Top" do |c|
      c.context_menu = "Pane/Alignment/Top"
      c.command do
        pane.tab_position = :top
        pane.tab_angle    = :horizontal
      end
    end
    
    command "Panes/Alignment/Left" do |c|
      c.context_menu = "Pane/Alignment/Left"
      c.command do
        pane.tab_position = :left
        pane.tab_angle    = :bottom_to_top
      end
    end
    
    command "Panes/Alignment/Right" do |c|
      c.context_menu = "Pane/Alignment/Right"
      c.command do
        pane.tab_position = :right
        pane.tab_angle    = :top_to_bottom
      end
    end
    
    command "Panes/Alignment/Bottom" do |c|
      c.context_menu = "Pane/Alignment/Bottom"
      c.command do
        pane.tab_position = :bottom
        pane.tab_angle    = :horizontal
      end
    end
  end
end
