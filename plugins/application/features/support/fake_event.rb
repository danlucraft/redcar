require 'ostruct'

class FakeEvent
  def initialize(event_type, widget, options = {})
    untyped_event = Swt::Widgets::Event.new.tap do |e|
      e.display = Swt.display
      e.widget = widget
      e.x = options[:x] || 0
      e.y = options[:y] || 0
      e.button = options[:button] if options[:button]
    end
    widget.notify_listeners(event_type, untyped_event)
  end
end

class FakeKeyEvent
  def initialize(key_code, widget)
    event = Swt::Widgets::Event.new
    event.display = Swt.display
    event.widget  = widget
    event.type    = Swt::SWT::KeyDown
    event.keyCode = key_code

    widget.notify_listeners(event.type,event)
  end
end