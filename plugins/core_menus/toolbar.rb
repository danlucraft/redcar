

module Redcar::Plugins::CoreMenus
  module MainToolbar
    extend Redcar::CommandBuilder
    extend Redcar::ToolbarBuilder
    
    toolbar "Main/New",  :icon => :NEW, :tooltip => "Create a new file",
                         :command => "Core/File/New"
    
    toolbar "Main/Open", :icon => :OPEN, :tooltip => "Open an existing file",
                         :command => "Core/File/Open"
    
    toolbar "Main/Save", :icon => :SAVE, :tooltip => "Save the current file",
                         :command => "Core/File/Save"
    
    toolbar "Main/Save As", :icon => :SAVE_AS, :command => "Core/File/Save As"
    
    toolbar_separator "Main"
    
    toolbar "Main/Cut", :icon => :CUT, :command => "Core/Edit/Cut"
    toolbar "Main/Copy", :icon => :COPY, :command => "Core/Edit/Copy"
  end
end
