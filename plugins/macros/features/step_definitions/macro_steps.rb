When /I start recording a macro/ do
  Redcar::Macros::StartStopRecordingCommand.new.run
end

When /I stop recording a macro/ do
  Redcar::Macros::StartStopRecordingCommand.new.run
end

When /I run the last recorded macro/ do
  Redcar::Macros::RunLastCommand.new.run
end

When /^I type "([^"]*)"$/ do |text|
  text = text.gsub("\\t", "\t").gsub("\\n", "\n")
  text.split(//).each do |letter|
    edit_view = Redcar::EditView.focussed_edit_view
    edit_view.type_character(letter[0])
  end
end

edit_view_action_steps = {
  :LINE_UP                => "I move up",
  :LINE_DOWN              => "I move down",
  :LINE_START             => "I move to the start of the line",
  :LINE_END               => "I move to the end of the line",
  :COLUMN_PREVIOUS        => "I move left",
  :COLUMN_NEXT            => "I move right",
  :PAGE_UP                => "I page up",
  :PAGE_DOWN              => "I page down",
  :WORD_PREVIOUS          => "I move to the previous word",
  :WORD_NEXT              => "I move to the next word",
  :TEXT_START             => "I move to the start of the text",
  :TEXT_END               => "I move to the end of the text",
  :WINDOW_START           => "I move to the start of the window",
  :WINDOW_END             => "I move to the end of the window",
  :SELECT_ALL             => "I select all",
  :SELECT_LINE_UP         => "I select up",
  :SELECT_LINE_DOWN       => "I select down",
  :SELECT_LINE_START      => "I select to the start of the line",
  :SELECT_LINE_END        => "I select to the end of the line",
  :SELECT_COLUMN_PREVIOUS => "I select left",
  :SELECT_COLUMN_NEXT     => "I select right",
  :SELECT_PAGE_UP         => "I select page up",
  :SELECT_PAGE_DOWN       => "I select page down",
  :SELECT_WORD_PREVIOUS   => "I select to the previous word",
  :SELECT_WORD_NEXT       => "I select to the next word",
  :SELECT_TEXT_START      => "I select to the start of the text",
  :SELECT_TEXT_END        => "I select to the end of the text",
  :SELECT_WINDOW_START    => "I select to the start of the window",
  :SELECT_WINDOW_END      => "I select to the end of the window",
  :CUT                    => "dsafjl;fjsadfk",
  :COPY                   => "asdfkjalsgj",
  :PASTE                  => "asdfasdfe",
  :DELETE_PREVIOUS        => "I backspace",
  :DELETE_NEXT            => "I delete",
  :DELETE_WORD_PREVIOUS   => "I delete to the previous word",
  :DELETE_WORD_NEXT       => "I delete to the next word"
}

edit_view_action_steps.each do |action_symbol, step_text|
  When step_text do
    Redcar::EditView.focussed_edit_view.invoke_action(action_symbol)
  end
end


