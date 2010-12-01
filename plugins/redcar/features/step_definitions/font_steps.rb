When /^I set the font size to (\d+|maximum|minimum)$/ do |arg1|
  if arg1 =~ /\d+/
    size = arg1.to_i
  elsif arg1 == 'maximum'
    size = Redcar::EditView::MAX_FONT_SIZE
  else
    size = Redcar::EditView::MIN_FONT_SIZE
  end
  Given "I would type \"#{size}\" in an input box"
  When "I set the font size"
end

When /^I (de|in)crease the font size$/ do |direction|
  if direction == 'in'
    Redcar::Top::IncreaseFontSize.new.run
  else
    Redcar::Top::DecreaseFontSize.new.run
  end
end

When /^I set the font size$/ do
  Redcar::Top::SelectFontSize.new.run
end

Then /^the font size should be (\d+|maximum|minimum)$/ do |size|
  current = Redcar::EditView.font_size
  if size =~ /\d+/
    current.should == size.to_i
  elsif size == 'maximum'
    current.should == Redcar::EditView::MAX_FONT_SIZE
  else
    current.should == Redcar::EditView::MIN_FONT_SIZE
  end
end
