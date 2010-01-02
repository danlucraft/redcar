module Redcar
  # A type of dialog containing a textbox and a list. Used to create the Find File dialog.
  class FilterListDialog
    include Redcar::Model
    include Redcar::Observable
    
    def initialize
      self.controller = Redcar.gui.controller_for(self).new(self)
    end
    
    def open
      notify_listeners(:open)
    end
    
    def starting_list
      %w(foo bar baz qux quux corge)
    end
    
    def update_list(filter)
      a = []
      5.times {|i| a << filter + " " + i.to_s }
      a
    end
    
    def selected(text)
      puts "Hooray! You selected #{text}"
    end
  end
end
