
module SwtKeyHelper
  def keypress(key)
    post(Swt::SWT::KeyDown, 0, 4194304)
    post(Swt::SWT::KeyDown, 110, 110)
    post(Swt::SWT::KeyUp, 110, 110)
    post(Swt::SWT::KeyUp, 0, 4194304)
  end
  
  def post(type, char, keycode)
    event = Swt::Widgets::Event.new
    event.type = type
    event.character = char
    event.keyCode = keycode
    Redcar::ApplicationSWT.display.post(event)
  end
end

World(SwtKeyHelper)

When /^I press "([^\"]*)"$/ do |key|
  keypress(key)
  while Redcar::ApplicationSWT.display.read_and_dispatch
    
  end
end
