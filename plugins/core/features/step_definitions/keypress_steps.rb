
def clean_letter(letter)
  if letter.include? "Tab"
    "Tab"
  else
    letter.split(" ").join("_")
  end
end

def inspect_event_key(gdk_event_key)
  kv = gdk_event_key.keyval
  ks = gdk_event_key.state - Gdk::Window::MOD2_MASK
  ks = ks - Gdk::Window::MOD4_MASK
  key = Gtk::Accelerator.get_label(kv, ks)
  # puts "pressing: #{key.inspect}"
  return kv, ks, key
end

When /^I wait for all GUI events to be processed$/ do
  while Gtk.events_pending?
    while Gtk.events_pending?
      Gtk.main_iteration
    end
    sleep 0.1
  end
end

When /^I press "(.*)"$/ do |key|
  # puts "pressing: #{key}"
  bits = key.split("+")
  ctrl = (bits.include?("Ctrl")  ? true : false)
  alt  = (bits.include?("Alt")   ? true : false)
  supr = (bits.include?("Super") ? true : false)
  letter = clean_letter(bits.last)
  shift = (bits.include?("Shift") && (letter =~ /^[[:alpha:]]$/ or letter.length > 1)? true : false)
  new_event_key = Gdk::EventKey.new(Gdk::Event::KEY_RELEASE)
  
  new_mod_mask = 0
  new_mod_mask |= Gdk::Window::ModifierType::SHIFT_MASK if shift
  new_mod_mask |= Gdk::Window::ModifierType::CONTROL_MASK if ctrl
  new_mod_mask |= Gdk::Window::ModifierType::MOD1_MASK if alt
  new_mod_mask |= Gdk::Window::ModifierType::SUPER_MASK if supr
  new_mod_mask = Gdk::Window::ModifierType.new(new_mod_mask)
  new_event_key.state = new_mod_mask
  new_event_key.keyval = Gdk::Keyval.from_name(letter)
  
  inspect_event_key(new_event_key)
  new_event_key.window = Redcar.win.window
  new_event_key.put
end





