
module Redcar
  class Command
    extend FreeBASE::StandardPlugin

    def self.execute(name)
      if name.is_a? String
        command = bus['/redcar/commands/'+name].data
      else
        command = name
      end
      begin
        command.execute
      rescue Object => e
        process_command_error(command.name, e)
      end
    end
  
    def self.process_command_error(name, e)
      puts "* Error in command: #{name}"
      puts "  trace:"
      puts e.to_s
      puts e.backtrace
    end
    
    attr_accessor(:name, :scope, :key)

    def execute
      puts "executing: #{@name}"
    end
  end
  
  class InlineCommand < Command
    attr_accessor(:sensitive, :block)
    
    def execute
      super
      begin
        if @block.is_a? Proc
          @block.call
        else
          (@block ||= eval("Proc.new {\n"+@block+"\n}")).call
        end
      rescue Object => e
        puts e.message
        puts e.backtrace
      end
    end
  end
  
  class ShellCommand < Command
    attr_accessor(:input, :output, :fallback_input,
                  :tm_uuid, :bundle_uuid)
    
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
    
    def execute
      super
      set_environment_variables
      File.open("cache/tmp.command", "w") {|f| f.puts @block}
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
      direct_output(@output, output) if output
    end
    
    def set_environment_variables
      ENV['RUBYLIB'] = (ENV['RUBYLIB']||"")+":textmate/Support/lib"
      
      ENV['TM_RUBY'] = "/usr/bin/ruby"
      if @bundle_uuid
        ENV['TM_BUNDLE_SUPPORT'] = Redcar.image[@bundle_uuid][:directory]+"Support"
      end
      if tab and tab.class.to_s == "Redcar::TextTab"
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
    
    # Gets the applicable input type, as a symbol. NOT the 
    # actual input
    def valid_input_type
      if primary_input
        @input
      else
        @fallback_input
      end
    end
    
    # Gets the primary input.
    def primary_input
      input = input_by_type(@input)
      input == "" ? nil : input
    end
    
    def secondary_input
      input_by_type(@fallback_input)
    end
    
    def input_by_type(type)
      case type
      when :selected_text, :selection, :selectedText
        tab.selection
      when :document
        tab.buffer.text
      when :line
        tab.get_line
      when :word
        if tab.cursor_iter.inside_word?
          s = tab.cursor_iter.backward_word_start!.offset
          e = tab.cursor_iter.forward_word_end!.offset
          tab.text[s..e].rstrip.lstrip
        end
      when :character
        tab.text[tab.cursor_iter.offset]
      when :scope
        if tab.respond_to? :current_scope_text
          tab.current_scope_text
        end
      when :nothing
        nil
      end
    end
    
    def get_input
      primary_input || secondary_input
    end
    
    def output=(val)
      @output_contents = val
    end
    
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
        new_tab.name = "output: " + @name
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
          if tab.respond_to? :current_scope
            s = tab.iter(tab.current_scope.start).offset
            e = tab.iter(tab.current_scope.end).offset
            tab.delete(s, e)
            tab.insert(s, output)
          end
        end
      when :show_as_html, :showAsHTML
        new_tab = Redcar.new_tab(HtmlTab, output.to_s)
        new_tab.name = "output: " + @name
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
    
    def shell_command
      if @block[0..1] == "#!"
        "./cache/tmp.command"
      else
        "/bin/sh cache/tmp.command"
      end
    end
  end
  
  module CommandBuilder
    def UserCommands(scope="", &block)
      CommandBuilder.selfobj = self
      CommandBuilder.db_scope = self.to_s+"/" + scope
      CommandBuilder.class_eval(&block)
    end

    class << self
      attr_accessor :db_scope, :selfobj
      
      def method_added(name)
        if @annotations
          com           = InlineCommand.new
          com.name      = "#{db_scope}/#{name}".gsub("//", "/")
          com.scope     = @annotations[:scope]
          com.sensitive = @annotations[:sensitive]
          com.block     = Proc.new { @selfobj.send(name) }
          if @annotations[:key]
            com.key = @annotations[:key].split("/").last
            Keymap.register_key(@annotations[:key], com)
          end
          bus("/redcar/commands/#{com.name}").data = com
          if @annotations[:menu]
            MenuBuilder.item "menubar/"+@annotations[:menu], com.name
          end
        end
        @annotations = nil
      end
      
      def annotate(name, val)
        @annotations ||= {}
        @annotations[name] = val
      end
      
      def menu(menu)
        annotate :menu, menu
      end
      
      def icon(icon)
        annotate :icon, icon
      end
      
      def key(key)
        annotate :key, key
      end
      
      def scope(scope)
        annotate :scope, scope
      end
      
      def sensitive(sens)
        annotate :sensitive, sens
      end
      
      def primitive(prim)
        annotate :primitive, prim
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
