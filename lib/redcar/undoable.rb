
module Redcar
  module Undoable
    UndoItem = Struct.new(:method_name, :args)

    def Undoable.append_features(destclass)
      def destclass.undo_composable(&block)
        @@compose_blocks ||= []
        @@compose_blocks << block
      end
      
      super
    end
    
    def any_undo?
      if defined? @undo_stack
        !@undo_stack.empty?
      end
    end

    def undoable(&block)
      @undo_stack ||= []
      @open_undo_stack ||= @undo_stack
      if @open_undo_stack == @undo_stack
        (@undo_stack ||= []) << (newstack=[])
        @open_undo_stack = newstack
        yield
        @open_undo_stack = @undo_stack
      else
        yield
      end
    end
    
    def clear_undo
      @undo_stack = []
      @open_undo_stack = @undo_stack
      Redcar.event :undo_status, self
    end
    
    def undo_array
      @undo_stack.map do |item|
        item.to_s
      end
    end
  
    def undo_stack
      @undo_stack
    end
  
    # Record the inverse of the method being called.
    def to_undo(method_name=nil, *args, &block)
      Redcar.event :undo_status, self do
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
end
