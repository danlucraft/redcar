
def make_event_key(key, type)
  bits = key.split("+")
  ctrl = (bits.include?("Ctrl")  ? true : false)
  alt  = (bits.include?("Alt")   ? true : false)
  supr = (bits.include?("Super") ? true : false)
  letter = bits.last

  shift = (bits.include?("Shift") && (letter =~ /^[[:alpha:]]$/ or letter.length > 1)? true : false)
  case type
  when :release
    new_event_key = Gdk::EventKey.new(Gdk::Event::KEY_RELEASE)
  when :press
    new_event_key = Gdk::EventKey.new(Gdk::Event::KEY_PRESS)
  end
  
  new_mod_mask = 0
  new_mod_mask |= Gdk::Window::ModifierType::SHIFT_MASK if shift
  new_mod_mask |= Gdk::Window::ModifierType::CONTROL_MASK if ctrl
  new_mod_mask |= Gdk::Window::ModifierType::MOD1_MASK if alt
  new_mod_mask |= Gdk::Window::ModifierType::SUPER_MASK if supr
  new_mod_mask = Gdk::Window::ModifierType.new(new_mod_mask)
  new_event_key.state = new_mod_mask
  if letter.length > 1
    keyval = Gdk::Keyval.from_name(letter)
    if keyval == 0
      keyval = Gdk::Keyval.from_name(letter.downcase)
    end
  else
    keyval = letter[0]
  end
  new_event_key.keyval = keyval
  new_event_key.hardware_keycode = Gdk::Keymap.default.get_entries_for_keyval(keyval).first.first
  new_event_key.window = Redcar.win.window
  new_event_key
end

def inspect_event_key(gdk_event_key)
  kv = gdk_event_key.keyval
  ks = gdk_event_key.state - Gdk::Window::MOD2_MASK
  ks = ks - Gdk::Window::MOD4_MASK
  key = Gtk::Accelerator.get_label(kv, ks)
  # puts "pressing: #{key.inspect}"
  return kv, ks, key
end

def press_key(key)
  make_event_key(key, :press).put
  make_event_key(key, :release).put
end

When /^I press #{FeatureHelpers::STRING_RE}(?: then #{FeatureHelpers::STRING_RE})?$/ do |key1, key2|
  press_key(key1)
  press_key(key2) if key2
end





