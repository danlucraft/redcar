
# the GUI uses this to decide what to display. You must implement updating
# yourself.
class TreeModel
  class Node
    attr_reader :id, :text, :icon, :parent
    
    # events: changed
    def initialize(mirror, id, text, icon=nil)
      @mirror, @id, @text, @icon = mirror, id, text, icon
    end
    
    def children
      
    end
    
    def leaf?
      
    end
  end
  
  def title
    
  end
  
  def top
    
  end
end

# Handles user actions
class TreeController
  # Double click / Enter
  def activated(node)
    
  end
  
  # Click
  def selected(nodes)
    
  end
  
  # Right click
  def alt_activated(node)
    
  end
end

