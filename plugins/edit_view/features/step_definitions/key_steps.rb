
module SwtKeyHelper
  def keypress(key)
    if key =~ /^Cmd/
      mod_key = 4194304
      char = key.downcase[-1]
      keycode = key.downcase[-1]
    elsif key =~ /^Ctrl/
      mod_key = 262144
      keycode = key.downcase[-1]
      char = key.downcase[-1] - "A".downcase[-1] + 1
    else
      raise "unknown mod key"
    end
    post(Swt::SWT::KeyDown, 0, mod_key, 0)
    post(Swt::SWT::KeyDown, char, keycode, mod_key)
    post(Swt::SWT::KeyUp, char, keycode, mod_key)
    post(Swt::SWT::KeyUp, 0, mod_key, mod_key)
  end
  
  def post(type, char, keycode, state_mask)
    p [:post, type, char, keycode, state_mask]
    event = Swt::Widgets::Event.new
    event.type = type
    event.character = char
    event.keyCode = keycode
    event.stateMask = state_mask
    Redcar::ApplicationSWT.display.post(event)
  end
end

World(SwtKeyHelper)

When /^I press m"([^\"]*)" l"([^\"]*)" w"([^\"]*)"$/ do |key_mac, key_linux, key_windows|
  case Redcar.platform
  when :osx
    key = key_mac
  when :linux
    key = key_linux
  when :windows
    key = key_windows
  end
puts "pressing #{key}"
  keypress(key)
  while Redcar::ApplicationSWT.display.read_and_dispatch
    
  end
end
