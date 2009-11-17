
module SwtKeyHelper
  def keypress(key)
    if key =~ /^Cmd/
      mod_key = 4194304
    elsif key =~ /^Ctrl/
      mod_key = 262144
    else
      raise "unknown mod key"
    end
    post(Swt::SWT::KeyDown, 0, mod_key, mod_key)
    post(Swt::SWT::KeyDown, key.downcase[-1], key.downcase[-1], mod_key)
    post(Swt::SWT::KeyUp, key.downcase[-1], key.downcase[-1], mod_key)
    post(Swt::SWT::KeyUp, 0, mod_key, mod_key)
  end
  
  def post(type, char, keycode, state_mask)
    event = Swt::Widgets::Event.new
    event.type = type
    event.character = char
    event.keyCode = keycode
    event.state_mask = state_mask
    Redcar::ApplicationSWT.display.post(event)
  end
end

World(SwtKeyHelper)

When /^I press m"([^\"]*)" l"([^\"]*)" w"([^\"]*)"$/ do |key_mac, key_linux, key_windows|
  case Redcar::Core.platform
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
