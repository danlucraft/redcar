
module Redcar
  class Command
    extend FreeBASE::StandardPlugin
        
    def self.add_command(id, block)
      @@commands ||= {}
      @@commands[id] = block
    end
    
    def self.command(id)
      @@commands[id].call(Redcar.current_pane, Redcar.current_tab)
    end  
    
    INPUTS = [
              "None", "Document", "Line", "Word", 
              "Character", "Scope", "Nothing", 
              "Selected Text"
             ]
    OUTPUTS = [
               "Discard", "Replace Selected Text", 
               "Replace Document", "Replace Line", "Insert As Text", 
               "Insert As Snippet", "Show As Html",
               "Show As Tool Tip", "Create New Document",
               "Replace Input", "Insert After Input"
              ]
    ACTIVATIONS = ["Key Combination"]
    
    def self.execute(name)
      if name.is_a? String
        b = $BUS['/redcar/commands/'+name].data
      else
        b = name
      end
      command = Command.new(b)
      begin
        command.execute
      rescue Object => e
        process_command_error(command_def[:name], e)
      end
    end
  
    def self.process_command_error(name, e)
      puts "* Error in command: #{name}"
      puts "  trace:"
      puts e.to_s
      puts e.backtrace
    end
    
    attr_accessor :def
    
    def initialize(hash)
      @def = hash
    end
    
    # Gets the applicable input type, as a symbol. NOT the 
    # actual input
    def valid_input_type
      if primary_input
        @def[:input]
      else
        @def[:fallback_input]
      end
    end
    
    # Gets the primary input.
    def primary_input
      input = input_by_type(@def[:input])
      input == "" ? nil : input
    end
    
    def secondary_input
      input_by_type(@def[:fallback_input])
    end
    
    def input_by_type(type)
      case type
      when :selected_text, :selection, :selectedText
        Redcar.current_tab.selection
      when :document
        Redcar.current_tab.buffer.text
      when :line
        Redcar.current_tab.get_line
      when :word
        if Redcar.current_tab.cursor_iter.inside_word?
          s = Redcar.current_tab.cursor_iter.backward_word_start!.offset
          e = Redcar.current_tab.cursor_iter.forward_word_end!.offset
          Redcar.current_tab.text[s..e].rstrip.lstrip
        end
      when :character
        Redcar.current_tab.text[Redcar.current_tab.cursor_iter.offset]
      when :scope
        if Redcar.current_tab.respond_to? :current_scope_text
          Redcar.current_tab.current_scope_text
        end
      when :nothing
        nil
      end
    end
    
    def get_input
      primary_input || secondary_input
    end
    
    def tab
      Redcar.current_tab
    end
    
    def pane
      Redcar.current_pane
    end
    
    def output=(val)
      @output = val
    end
    
#     OUTPUTS = [
#                "Discard", "Replace Selected Text", 
#                "Replace Document", "Insert As Text", 
#                "Insert As Snippet", "Show As HTML",
#                "Show As Tool Tip", "Create New Document",
#                "Replace Input", "Insert After Input"
#               ]
    def direct_output(type, output)
      case type
      when :replace_document, :replaceDocument
        tab.replace output
      when :replace_line, :replaceLine
        tab.replace_line(output)
      when :replace_selected_text, :replaceSelectedText
        tab.replace_selection(output)
      when :insert_as_text, :insertAsText
        tab.insert_at_cursor(output)
      when :insert_as_snippet, :insertAsSnippet
        tab.insert_as_snippet(output)
      when :show_as_tool_tip, :show_as_tooltip, :showAsTooltip
        tab.tooltip_at_cursor(output)
      when :after_selected_text, :afterSelectedText
        if tab.selected?
          s, e = tab.selection_bounds
        else
          e = tab.cursor_offset
        end
        tab.insert(e, output)
      when :create_new_document, :createNewDocument
        new_tab = Redcar.current_pane.new_tab
        new_tab.name = "output: " + @def[:name]
        new_tab.replace output
        new_tab.focus
      when :replace_input, :replaceInput
        case valid_input_type
        when :selected_text, :selectedText
          tab.replace_selection(output)
        when :line
          tab.replace_line(output)
        when :document
          tab.replace output
        when :word
          Redcar.tab.text[@s..@e] = output
        when :scope
          if Redcar.current_tab.respond_to? :current_scope
            s = tab.iter(Redcar.current_tab.current_scope.start).offset
            e = tab.iter(Redcar.current_tab.current_scope.end).offset
            tab.delete(s, e)
            tab.insert(s, output)
          end
        end
      when :show_as_html, :showAsHTML
        new_tab = Redcar.new_tab(HtmlTab, output.to_s)
        new_tab.name = "output: " + @def[:name]
        new_tab.focus
      when :insert_after_input, :insertAfterInput
        case valid_input_type
        when :selected_text, :selectedText
          s, e = tab.selection_bounds
          offset = [s, e].sort[1]
          tab.insert(offset, output)
          tab.select(s+output.length, e+output.length)
        when :line
          if tab.cursor_line == tab.line_count-1
            tab.insert(tab.line_end(tab.cursor_line), "\n"+output)
          else
            tab.insert(tab.line_start(tab.cursor_line+1), output)
          end
        end
      end
    end
    
    def execute_as_inline
      @output = nil
      tab = Redcar.current_tab
      input = get_input
      begin
        if @def[:command].is_a? Proc
          output = @def[:command].call
        else
          output = (@block ||= eval("Proc.new {\n"+@def[:command]+"\n}")).call
        end
      rescue Object => e
        puts e.message
        puts e.backtrace
      end
      output ||= @output
      direct_output(@def[:output], output) if output
    end

    def shell_command
      if @def[:command][0..1] == "#!"
        "./cache/tmp.command"
      else
        "/bin/sh cache/tmp.command"
      end
    end
    
    def execute_as_shell
      File.open("cache/tmp.command", "w") {|f| f.puts @def[:command]}
      File.chmod(0770, "cache/tmp.command")
      output, error = nil, nil
      Open3.popen3(shell_command) do |stdin, stdout, stderr|
        stdin.write(input = get_input)
        puts "input: #{input}"
        stdin.close
        output = stdout.read
        puts "output: #{output}"
        error = stderr.read
      end
      unless error.blank?
        puts "shell command failed with error:"
        puts error
      end
      direct_output(@def[:output], output) if output
    end
    
    def execute
      puts "executing: #{self.def['name']}"
      set_environment_variables
      case @def[:type]
      when :inline
        execute_as_inline
      when :shell
        execute_as_shell
      end
    end
    
    # Shell commands
    def set_environment_variables
      ENV['RUBYLIB'] = (ENV['RUBYLIB']||"")+":textmate/Support/lib"
      
      ENV['TM_RUBY'] = "/usr/bin/ruby"
      if @def[:bundle_uuid]
        ENV['TM_BUNDLE_SUPPORT'] = Redcar.image[@def[:bundle_uuid]][:directory]+"Support"
      end
      if tab and tab.is_a? TextTab
        ENV['TM_CURRENT_LINE'] = tab.get_line
        ENV['TM_LINE_INDEX'] = tab.cursor_line_offset.to_s
        ENV['TM_LINE_NUMBER'] = (tab.cursor_line+1).to_s
        if tab.selected?
          ENV['TM_SELECTED_TEXT'] = tab.selection
        end
        if tab.filename
          ENV['TM_DIRECTORY'] = File.dirname(tab.filename)
          ENV['TM_FILEPATH'] = tab.filename
        end
        if tab.sourceview.grammar
          ENV['TM_SCOPE'] = tab.scope_at_cursor.to_s
        end
        ENV['TM_SOFT_TABS'] = "YES"
        ENV['TM_SUPPORT_PATH'] = "textmate/Support"
        ENV['TM_TAB_SIZE'] = "2"
      end
    end
  end
  
  module CommandBuilder
    def command(name)
      b = Builder.new
      yield b
      slot = $BUS['/redcar/commands/'+name.to_s].data = b
      b.path = name
      if b.menu
        self.menu b.menu do |m|
          m.command = name
          m.icon = b.icon
        end
        unless b.name
          b.name = b.menu.split("/").last
        end
      end
      if b.context_menu
        self.context_menu b.context_menu do |m|
          m.command = name
          m.icon = b.icon
        end
      end
      if b.keybinding
        Redcar::Keymap["Application Wide"].add_command(b)
      end
      b.type ||= :inline
      b.tooltip ||= nil
      b.scope_selector ||= ""
      b.input ||= :none
      b.output ||= :discard
      b.fallback_input ||= :none
      b.icon ||= nil
      b.sensitive ||= :nothing
      b.name ||= ""
    end
    
    class Builder
      attr_accessor(:name, :type, :tooltip, :scope_selector, 
                    :input, :output, :fallback_input, :icon, :sensitive,
                    :menu, :keybinding, :context_menu, :tm_uuid, :path)
      def [](v)
        instance_variable_get("@"+v.to_s)
      end
      
      def command=(v)
        @command = v
      end
      
      def command(v=nil, &blk)
        if v
          @command = v
        elsif blk
          @command = blk
        end
      end
    end
  end
  
  module UserCommands
    def self.included(klass)
      klass.extend ClassMethods
    end
    
    module ClassMethods
      def start_commands
        @should_add = true
      end
      
      def end_commands
        @should_add = false
      end
      
      def user_commands(&block)
        @should_add = true
        self.class_eval(&block)
        @should_add = false
      end
      
      def method_added(meth)
        unless @adding
          if @should_add
            @adding = true
            self.class_eval do
              alias_method "__base_#{meth}", "#{meth}"
              define_method(meth) do |*args|
                unless defined? @recording
                  @recording = true
                end
                add_to_command_history([meth, args]) if @recording
                #puts "#{meth} called, recording:#{@recording.to_s}. Params = #{args.inspect}"
                was_on = @recording
                @recording = false
                result = nil
                begin
                  if self.class == Redcar::TextTab
                    self.buffer.begin_user_action
                  end
                  result = self.send("__base_#{meth}", *args)
                  if self.class == Redcar::TextTab
                    self.buffer.end_user_action
                  end
                rescue Object => e
                  Redcar.process_command_error(meth, e)
                end
                @recording = was_on
                result
              end
            end
            @adding = false
          end
        end
      end
    end
    
    def command_history
      @command_history
    end
    
    def clear_command_history
      @command_history = []
    end
    
    def add_to_command_history(command)
      @command_history ||= []
      @command_history << command
    end
  end  
end
