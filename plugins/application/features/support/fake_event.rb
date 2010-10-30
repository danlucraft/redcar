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
