
  
module Redcar
  class ShellTab < TextTab
    include Keymap
    
    keymap "Return", :execute_line
    
    def insert_at_cursor(str)
      if (@start_loc..contents.length).include? cursor_offset
        super
      end
    end
    
    def up
      @history_point ||= 0
      unless @history_point == -@history.length
        if @history_point == 0
          @current = contents[@start_loc..contents.length]
        end
        @history_point -= 1
        delete(@start_loc, contents.length)
        text = @history[@history_point]
        insert(@start_loc, text)
        self.cursor = @start_loc + text.length
      end
    end
    
    def down
      @history_point ||= 0
      if @history_point < -1
        @history_point += 1
        delete(@start_loc, contents.length)
        insert(@start_loc, @history[@history_point])
      elsif @history_point == -1
        @history_point += 1
        delete(@start_loc, contents.length)
        insert(@start_loc, @current)
        self.cursor = @start_loc + @current.length
      end
    end
    
    def left
      unless cursor_offset == @start_loc
        super
      end
    end
    
    def execute_line
      command_str = contents[@start_loc..contents.length]
      execute(command_str)
      @history << command_str
      display_prompt
    end
    
    def display_prompt
      prompt_text = prompt
      insert(contents.length, "\n"+prompt_text)
      @start_loc = contents.length
    end
    
    def output(str)
      insert(contents.length, "\n"+str)
    end
    
    def initialize(blurb, pane)
      super(pane)
      insert(contents.length, blurb)
      display_prompt
      @history = []
    end
  end
end
