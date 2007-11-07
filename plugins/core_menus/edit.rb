
module Redcar::Plugins::CoreMenus
  module EditMenu
    extend Redcar::CommandBuilder
    extend Redcar::MenuBuilder
    
    command "Core/Edit/Undo" do |c|
      c.menu = "Edit/Undo"
      c.icon = :UNDO
      c.command %q{ tab.undo }
      c.sensitive = :can_undo?
      c.keybinding = "control z"
    end
    
    command "Core/Edit/Redo" do |c|
      c.menu = "Edit/Redo"
      c.icon = :REDO
      c.command %q{ tab.redo }
      c.sensitive = :can_redo?
      c.keybinding = "alt-control z"
    end
    
    menu_separator "Edit"
    
    command "Core/Edit/Copy" do |c|
      c.menu = "Edit/Copy"
      c.keybinding = "control c"
      c.icon = :COPY
      c.sensitive = :text_selected?
      c.command = %{tab.copy}
    end
    
    command "Core/Edit/Cut" do |c|
      c.menu = "Edit/Cut"
      c.keybinding = "control x"
      c.icon = :CUT
      c.sensitive = :text_selected?
      c.command = %{tab.cut}
    end
    
    command "Core/Edit/Paste" do |c|
      c.menu = "Edit/Paste"
      c.keybinding = "control v"
      c.icon = :PASTE
      c.sensitive = :can_paste?
      c.command = %{tab.paste}
    end
    
    menu_separator "Edit"
    
    command "Core/Edit/Duplicate" do |c|
      c.menu = "Edit/Duplicate"
      c.keybinding = "control-shift D"
      c.icon = :COPY
      c.sensitive = :current_tab_is_text_tab?
      c.input = :selected_text
      c.fallback_input = :line
      c.output = :insert_after_input
      c.command %q{ input }
    end
    
    command "Core/Edit/Select All" do |c|
      c.menu = "Edit/Select/All"
      c.keybinding = "control-shift A"
      c.icon = :SELECT_ALL
      c.sensitive = :current_tab_is_text_tab?
      c.command %{ tab.select(0, tab.char_count) }
    end
    
    command "Core/Edit/Select Character" do |c|
      c.menu = "Edit/Select/Character"
      c.sensitive = :current_tab_is_text_tab?
      c.command %{ 
        tab.select(
          tab.cursor_offset, 
          [tab.cursor_offset+1, tab.char_count].min
        )
      }
    end
    
    command "Core/Edit/Select Character" do |c|
      c.menu = "Edit/Select/Word"
      c.sensitive = :current_tab_is_text_tab?
      c.keybinding = "control w"
      c.command %{ 
        if tab.cursor_iter.inside_word?
          s = tab.cursor_iter.backward_word_start!.offset
          e = tab.cursor_iter.forward_word_end!.offset
          s1, e1 = [s, e].sort
          tab.select(s1, e1)
        end
      }
    end
    
    command "Core/Edit/Select Line" do |c|
      c.menu = "Edit/Select/Line"
      c.sensitive = :current_tab_is_text_tab?
      c.keybinding = "shift-super L"
      c.command %{ 
        tab.select(
          tab.line_start(tab.cursor_line), 
          tab.line_end(tab.cursor_line)
        )
      }
    end
    
    command "Core/Edit/Forward Word" do |c|
      c.menu = "Edit/Move Cursor/Forward Word"
      c.keybinding = "control f"
      c.icon = :GO_FORWARD
      c.sensitive = :current_tab_is_text_tab?
      c.command = %{tab.forward_word}
    end
    
    command "Core/Edit/Backward Word" do |c|
      c.menu = "Edit/Move Cursor/Backward Word"
      c.keybinding = "control b"
      c.icon = :GO_BACK
      c.sensitive = :current_tab_is_text_tab?
      c.command = %{tab.backward_word}
    end
    
    command "Core/Edit/Line Start" do |c|
      c.menu = "Edit/Move Cursor/Line Start"
      c.keybinding = "control a"
      c.icon = :GOTO_FIRST
      c.sensitive = :current_tab_is_text_tab?
      c.command = %{ tab.cursor = :line_start }
    end
    
    command "Core/Edit/Line End" do |c|
      c.menu = "Edit/Move Cursor/Line End"
      c.keybinding = "control e"
      c.icon = :GOTO_LAST
      c.sensitive = :current_tab_is_text_tab?
      c.command = %{ tab.cursor = :line_end }
    end
    
    command "Core/Edit/Document Start" do |c|
      c.menu = "Edit/Move Cursor/Document Start"
      c.keybinding = "alt-shift <"
      c.icon = :GOTO_TOP
      c.sensitive = :current_tab_is_text_tab?
      c.command = %{ tab.cursor = 0 }
    end
    
    command "Core/Edit/Document End" do |c|
      c.menu = "Edit/Move Cursor/Document End"
      c.keybinding = "alt-shift >"
      c.icon = :GOTO_BOTTOM
      c.sensitive = :current_tab_is_text_tab?
      c.command = %{ tab.cursor = tab.char_count }
    end
    
    command "Core/Edit/Lower Case" do |c|
      c.menu = "Edit/Convert/to lower case"
      c.sensitive = :current_tab_is_text_tab?
      c.input = :selected_text
      c.fallback_input = :line
      c.command = %{input.downcase}
      c.output = :replace_input
      c.keybinding = "control-shift U"
    end
    
    command "Core/Edit/Title Case" do |c|
      c.menu = "Edit/Convert/to Title Case"
      c.sensitive = :current_tab_is_text_tab?
      c.input = :selected_text
      c.fallback_input = :line
      c.command %q{
        input.gsub(/\b([^\s]+)\b/) do |word| 
          word[0..0].upcase + word[1..-1].downcase
        end
      }
      c.output = :replace_input
      c.keybinding = "alt-control U"
    end
    
    command "Core/Edit/Upper Case" do |c|
      c.menu = "Edit/Convert/to UPPER CASE"
      c.sensitive = :current_tab_is_text_tab?
      c.input = :selected_text
      c.fallback_input = :line
      c.command %q{ input.upcase }
      c.output = :replace_input
      c.keybinding = "control U"
    end
    
    command "Core/Edit/Invert Case" do |c|
      c.menu = "Edit/Convert/iNVERT cASE"
      c.sensitive = :current_tab_is_text_tab?
      c.input = :selected_text
      c.fallback_input = :line
      c.command = %{input.swapcase}
      c.output = :replace_input
      c.keybinding = "control g"
    end
    
    
  end
end
