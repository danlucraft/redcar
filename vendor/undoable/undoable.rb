# Undoable

# Allows methods to specify their own inverse operation, thus making them
# undoable. Undo works like in emacs, where undos can be themselves undone.
#
# Copyright 2007 Daniel Lucraft
#
# = Usage
# === Undoing individual methods
# To allow undoing of a method, specify another method that is the method's inverse, or call
# to_undo with a block.
# 
#  class UndoableObject
#    include Undoable
#    
#    attr_reader :state
#    def initialize
#      @state = []
#    end
#    
#    def append(obj)
#      to_undo :pop
#      @state << obj
#    end
#    
#    def pop
#      r = @state.pop
#      to_undo :append, r
#      r
#    end   
#
#    def sort
#      c = @state.clone
#      to_undo do
#        @state = c
#      end
#      @state = @state.sort
#    end
#  end
#
#  uo = UndoableObject.new
#  uo.append(1)
#  uo.append(2)
#  uo.state    #=> [1, 2]
#  uo.undo
#  uo.state    #=> [1]
#  uo.pop
#  uo.state    #=> []
#  uo.undo
#  uo.state    #=> [1]
#  
#  uo = UndoableObject.new
#  uo.append_arr([2, 3, 1, 5, 4])
#  uo.sort
#  assert_equal [1, 2, 3, 4, 5], uo.state
#  uo.undo
#  assert_equal [2, 3, 1, 5, 4], uo.state
#
# == Composite Undoable Methods
# A method that calls individually undoable methods can be undone as a single action, by 
# calling undoable with a block.
#  class UndoableObject
#    include Undoable
#    
#    attr_reader :state
#    def initialize
#      @state = []
#    end
#    
#    def append(obj)
#      to_undo  :pop
#      @state << obj
#    end
#    
#    def pop
#      r = @state.pop
#      to_undo  :append, r
#      r
#    end 
#
#    def append_123
#      undoable do
#        append(1)
#        append(2)
#        append(3)
#      end
#    end  
#  end
# 
#  uo = UndoableObject.new
#  uo.append_123
#  uo.undo
#  assert_equal [], uo.state
#
# The individual undo items can still be undone one at a time with Undoable#undo_tiny
#
#  uo = UndoableObject.new
#  uo.append_123
#  uo.undo_tiny
#  assert_equal [1, 2], uo.state
#
# === Composability
# Specify how two undo actions can be composed into one with the undo_composable class method:
#
#   class UndoableObject
#     include Undoable
#
#     attr_accessor :state
#    
#     def initialize
#       @state = []
#     end
#   
#     def append_arr(arr)
#       to_undo  :remove_arr, arr.length
#       @state += arr
#     end
#   
#     def remove_arr(num)
#       to_undo  :append_arr, @state[-num..-1]
#       @state = @state[0..(-num-1)]
#     end
#   
#     undo_composable do |a, b|
#       if a.method_name == :append_arr and 
#           b.method_name == :append_arr
#         UndoItem.new(:append_arr, [b.args[0]+a.args[0]])
#       end
#     end
#   
#     undo_composable do |a, b|
#       if a.method_name == :remove_arr and
#           b.method_name == :remove_arr
#         UndoItem.new(:remove_arr, [a.args[0]+b.args[0]])
#       end
#     end
#   end
#
#   uo = UndoableObject.new
#   uo.append_arr([1, 2, 3])
#   uo.append_arr([10, 20, 30])
#   uo.undo
#   assert_equal [], uo.state
  
module Undoable
  UndoItem = Struct.new(:method_name, :args)

  def undo_array
    @undo_stack.map do |item|
      item.to_s
    end.join("\n")
  end
  
  def undo_stack
    @undo_stack.map do |item|
      item.inspect
    end
  end
  
  def undoable
    @undo_stack ||= []
    @open_undo_stack ||= @undo_stack
    if block_given?
      if @open_undo_stack == @undo_stack
        sub_stack = []
        @undo_stack << sub_stack
        @open_undo_stack = sub_stack
      end
      yield
      @open_undo_stack = @undo_stack
    end
  end
  
  # Record the inverse of the method being called.
  def to_undo(method_name=nil, *args, &block)
    @undo_stack ||= []
    @open_undo_stack ||= @undo_stack
    if block_given?
      @open_undo_stack << block
    else
      @open_undo_stack << UndoItem.new(method_name, args)
      compose = true
      @@compose_blocks ||= []
      while compose
        compose = false
        if @open_undo_stack.length > 1
          @@compose_blocks.each do |block|
            a, b = *@open_undo_stack[-2..-1]
            if a.is_a? UndoItem and b.is_a? UndoItem
              result = block.call(a, b)
              if result
                compose = true
                @open_undo_stack.pop 
                @open_undo_stack.pop
                @open_undo_stack << result
              end
            end
          end
        end
      end
    end
    @undo_point = @undo_stack.length
  end

  def Undoable.append_features(destclass)
    def destclass.undo_composable(&block)
      @@compose_blocks ||= []
      @@compose_blocks << block
    end
    
    super
  end
  
  # Undoes the last action, or the last composite action.
  def undo
    @undo_point ||= @undo_stack.length
    return nil if @undo_stack.empty? or @undo_point < 1
    top = @undo_stack[@undo_point-1]
    pre_undo_point = @undo_point
    if top.is_a? Array
      topclone = top.clone
      topclone.reverse.each do |item|
        self.send(item.method_name, *item.args)
      end
    elsif top.is_a? Proc
      top.call
    else
      self.send(top.method_name, *top.args)
    end
    @undo_point = pre_undo_point - 1
    return true
  end
  
  # Undoes the last action, or if this is a composite action, the last action
  # within that composition.
  def undo_tiny
    @undo_point ||= @undo_stack.length
    return if @undo_stack.empty?
    top = @undo_stack.pop
    top = top.pop if top.is_a? Array
    self.send(top.method_name, *top.args)
  end
end
