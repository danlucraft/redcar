
module Redcar
  class RedcarPlugin < Redcar::Plugin
    main_menu "File" do
      item "New",        NewTab
      item "Open",       OpenTab
      separator
      item "Save",       SaveTab
      item "Save As",    SaveTabAs
#      item "Revert",     RevertTab
      separator
      item "Close",      CloseTab
      item "Close All",  CloseAllTabs
      separator
      item "Quit",       Quit
    end

    main_menu "Edit" do
      item "Undo",     Undo
      item "Redo",     Redo
      separator
      item "Cut",      Cut
      item "Copy",     Copy
      item "Paste",    Paste
      separator
      item "Find",     Find
      submenu "Move" do
        item "Forward Character",    ForwardCharacterCommand
        item "Backward Character",   BackwardCharacterCommand
        separator
        item "Forward Word",    ForwardWordCommand
        item "Backward Word",   BackwardWordCommand
        separator
        item "Line Start",    LineStart
        item "Line End",   LineEnd
        separator
        item "Goto Line",  AskGotoLineCommand
      end
      item "Kill Line", KillLine
      separator
      item "Indent Line",    IndentLine
      separator
      submenu "Select" do
        item "Line",            SelectLine
        item "Current Scope",    SelectScopeCommand
      end
      separator
    end

    main_menu "Dans" do
      item "RubyEnd", RubyEnd
    end

    context_menu "Pane" do
      item "Split Horizontal",  SplitHorizontal
      item "Split Vertical",    SplitVertical
      item "Unify All",         UnifyAll
    end
  end
end
