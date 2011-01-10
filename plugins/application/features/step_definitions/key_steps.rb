key_presses = {
  "ARROW_UP" => "up arrow",
  "ARROW_DOWN" => "down arrow",
  "ARROW_LEFT" => "left arrow",
  "ARROW_RIGHT" => "right arrow",
  "CR" => "return",
  "BS" => "backspace",
  "HOME" => "home",
  "DEL" => "delete"
}
key_presses.each do |const,text|
  When "I press the #{text} key" do
    tab = Redcar.app.focussed_window.focussed_notebook_tab
    widget = tab.edit_view.controller.mate_text.get_control
    key = Swt::SWT.const_get(const)
    FakeKeyEvent.new(key,widget)
  end
end