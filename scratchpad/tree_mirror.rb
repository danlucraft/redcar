
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

# Handles 
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

# 
# # method based interface
# #
# # advantages: 
# #  * one object to hook events on to
# #  * no need to worry about invalidation
# 
# class TreeMirror
#   class Row < Struct.new(:id, :text, :icon, :leaf?); end
#   
#   def title
#     
#   end
#   
#   def top
#     
#   end
#   
#   def children_of(id)
#     
#   end
#   
#   def create_child_of(id)
#     
#   end
#   
#   def delete(id)
#     
#   end
#   
#   def activate(id)
#     
#   end
#   
#   def move(id, new_parent_id)
#     
#   end
# end
