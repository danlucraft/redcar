
require 'gtk2'

entry = Gtk::Entry.new
win = Gtk::Window.new
win.add(entry)

def inspect_event_key(gdk_event_key)
  p gdk_event_key
  return unless gdk_event_key
  puts "state:  #{gdk_event_key.state.inspect}"
  puts "keyval: #{gdk_event_key.keyval.inspect}"
  puts "group:  #{gdk_event_key.group.inspect}"
  puts "hardwa: #{gdk_event_key.hardware_keycode.inspect}"
  kv = gdk_event_key.keyval
  ks = gdk_event_key.state - Gdk::Window::MOD2_MASK
  ks = ks - Gdk::Window::MOD4_MASK
  key = Gtk::Accelerator.get_label(kv, ks)
  puts "label:  #{key.inspect}"
  return kv, ks, key
end

def clean_letter(letter)
  if letter.include? "Tab"
    "Tab"
  else
    letter.split(" ").join("_")
  end
end

def test_event_key(gdk_event_key)
  kv, ks, key = inspect_event_key(gdk_event_key)  
  puts
  unless key[-2..-1] == " L" or key[-2..-1] == " R"
    bits = key.split("+")
    p bits
    ctrl = (bits.include?("Ctrl")  ? true : false)
    alt  = (bits.include?("Alt")   ? true : false)
    supr = (bits.include?("Super") ? true : false)
    letter = clean_letter(bits.last)
    shift = (bits.include?("Shift") && (letter =~ /^[[:alpha:]]$/ or letter.length > 1)? true : false)
    new_event_key = Gdk::EventKey.new(Gdk::Event::KEY_RELEASE)

    new_mod_mask = 0
    p new_mod_mask
    new_mod_mask |= Gdk::Window::ModifierType::SHIFT_MASK if shift
    p new_mod_mask
    new_mod_mask |= Gdk::Window::ModifierType::CONTROL_MASK if ctrl
    p new_mod_mask
    new_mod_mask |= Gdk::Window::ModifierType::MOD1_MASK if alt
    p new_mod_mask
    new_mod_mask |= Gdk::Window::ModifierType::SUPER_MASK if supr
    p new_mod_mask
    new_mod_mask = Gdk::Window::ModifierType.new(new_mod_mask)
    p new_mod_mask
    new_event_key.state = new_mod_mask
    new_event_key.keyval = Gdk::Keyval.from_name(letter)
  end
  inspect_event_key(new_event_key)  
  
end

entry.signal_connect("key-press-event") do |_, gdk_event_key|
  puts
  test_event_key(gdk_event_key)
end

entry.signal_connect("button-press-event") do |_, event_button|
  p :button_in_entry
  p event_button
  p event_button.button
  p event_button.state
  p event_button.x
  p event_button.y
  puts
end

win.signal_connect("button-press-event") do |_, event_button|
  p :button_in_win
  p event_button
  p event_button.button
  p event_button.state
  p event_button.x
  p event_button.y
  puts
end

win.signal_connect("destroy") { Gtk.main_quit }

win.show_all
Gtk.main




