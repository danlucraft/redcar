
module Redcar
  # Encapsulates a Redcar command. Commands wrap the calling of a 
  # method (that is usually defined as a plugin class method) so that 
  # that method can be called through a keystroke or a menu option etc.
  #
  # This class also initializes the CommandHistory on startup.
  class Command
    extend FreeBASE::StandardPlugin

    def self.start(plugin)
      CommandHistory.clear
      plugin.transition(FreeBASE::RUNNING)
    end

    def self.stop(plugin)
      CommandHistory.clear
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.inherited(klass)
      bus("/redcar/commands/#{klass}").data = klass
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
    
    def self.menu(menu)
      @menu = menu
#      MenuBuilder.item "menubar/"+menu, self.class.to_s
    end
    
    def self.icon(icon)
      @icon = icon
    end
    
    def self.key(key)
      @key = key
    end
    
    def self.scope(scope)
      @scope = scope
    end
    
    def self.sensitive(sens)
      @sensitive ||= []
      @sensitive << sens
    end
    
    def self.inputs(*inputs)
      @input_types = inputs
    end
    
    def self.input(input)
      @input_types = [input]
    end
    
    def self.output(output)
      @output_type = output
    end
    
    def self.composite
      @composite = true
    end
    
    attr_accessor(:name, :scope, :key, :inputs, :output, :record)

    def execute
      puts "executing: #{@name}"
      raise "Abstract Command Error"
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
    
    def direct_output(type, output_contents)
      case type
      when :replace_document, :replaceDocument
        tab.replace output_contents
      when :replace_line, :replaceLine
        tab.replace_line(output_contents)
      when :replace_selected_text, :replaceSelectedText
        tab.replace_selection(output_contents)
      when :insert_as_text, :insertAsText
        tab.insert_at_cursor(output_contents)
      when :insert_as_snippet, :insertAsSnippet
        tab.insert_as_snippet(output_contents)
      when :show_as_tool_tip, :show_as_tooltip, :showAsTooltip
        tab.tooltip_at_cursor(output_contents)
      when :after_selected_text, :afterSelectedText
        if tab.selected?
          s, e = tab.selection_bounds
        else
          e = tab.cursor_offset
        end
        tab.insert(e, output_contents)
      when :create_new_document, :createNewDocument
        new_tab = Redcar.current_pane.new_tab
        new_tab.name = "output: " + @name
        new_tab.replace output_contents
        new_tab.focus
      when :replace_input, :replaceInput
        case valid_input_type
        when :selected_text, :selectedText
          tab.replace_selection(output_contents)
        when :line
          tab.replace_line(output_contents)
        when :document
          tab.replace output_contents
        when :word
          Redcar.tab.text[@s..@e] = output_contents
        when :scope
          if tab.respond_to? :current_scope
            s = tab.iter(tab.current_scope.start).offset
            e = tab.iter(tab.current_scope.end).offset
            tab.delete(s, e)
            tab.insert(s, output_contents)
          end
        end
      when :show_as_html, :showAsHTML
        new_tab = Redcar.new_tab(HtmlTab, output_contents.to_s)
        new_tab.name = "output: " + @name
        new_tab.focus
      when :insert_after_input, :insertAfterInput
        case valid_input_type
        when :selected_text, :selectedText
          s, e = tab.selection_bounds
          offset = [s, e].sort[1]
          tab.insert(offset, output_contents)
          tab.select(s+output_contents.length, e+output_contents.length)
        when :line
          if tab.cursor_line == tab.line_count-1
            tab.insert(tab.line_end(tab.cursor_line), "\n"+output_contents)
          else
            tab.insert(tab.line_start(tab.cursor_line+1), output_contents)
          end
        end
      end
    end
    
  end
  
  class InlineCommand < Command
    attr_accessor(:sensitive, :block)
    
    def execute
      super
      output_str = nil
      begin
        output_str = if @block.arity == 1
                       @block.call(get_input)
                     else
                       @block.call
                     end
      rescue Object => e
        puts e.message
        puts e.backtrace
      end
      direct_output(@output, output_str) if output_str
    end
  end
  
  class ShellCommand < Command
    attr_accessor(:fallback_input,
                  :tm_uuid, :bundle_uuid)
    
    
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
    
    def shell_command
      if @block[0..1] == "#!"
        "./cache/tmp.command"
      else
        "/bin/sh cache/tmp.command"
      end
    end
  end
  
  # A module holding the Redcar command history. The maximum length
  # defaults to 500.
  module CommandHistory
    class << self
      attr_accessor :max, :recording, :history
    end
    
    self.max       = 500
    self.recording = true
    
    # Add a command to the command history if CommandHistory.recording is
    # true.
    def self.record(com)
      if recording and com.record
        @history << com
      end
      prune
    end
    
    def self.prune #:nodoc:
      (@history.length-@max).times { @history.delete_at(0) }
    end
    
    # Clear the command history.
    def self.clear
      @history = []
    end
  end
  
  # The CommandBuilder allows you to create a Redcar::Command around
  # a class method. See Redcar::Plugin for examples of how to create
  # commands. This module is automatically included in plugins inheriting
  # from Redcar::Plugin, but may be added to any class:
  #   class MyRandomClass
  #     Redcar::CommandBuilder.enable(self)
  #   end
  module CommandBuilder

    # Add the tab_commands class method to your tab class to 
    # allow you to wrap instance methods on your tab as 
    # commands.
    def self.enable_tab(klass)
        def self.method_added(method_name) #:nodoc:
          if @defining_commands and !@aliasing
            @annotations ||= {}
            com           = InlineCommand.new
            com.name      = "#{__db_scope}/#{method_name}".gsub("//", "/")
            com.scope     = @annotations[:scope]
            com.sensitive = @annotations[:sensitive]
            com.record    = (@annotations[:record] == nil ? true : @annotations[:record])
            com.block     = Proc.new {
              Redcar::App.
              focussed_window.
              focussed_tab.send(method_name) 
            }
            com.inputs    = @annotations[:inputs]
            com.output    = @annotations[:output]
            if @annotations[:key]
              com.key = @annotations[:key].split("/").last
              Keymap.register_key(@annotations[:key], com)
            end
            bus("/redcar/commands/#{com.name}").data = com
            if @annotations[:menu]
              MenuBuilder.item "menubar/"+@annotations[:menu], com.name
            end
            @aliasing = true
            if @aliasing
              newname = ("__defined_"+method_name.to_s).intern
              @aliasing = true
              self.send(:alias_method, newname, method_name)
              self.send(:define_method, method_name) do
                CommandHistory.record(com)
                CommandHistory.recording = false
                Redcar::App.focussed_window.focussed_tab.send(newname)
                CommandHistory.recording = true
              end
              @aliasing = false
            end
            @aliasing = false
            @annotations = nil
            stop_defining_commands if @one_command_only
          end
        end
    end
    
    # Add the user_command class method to your class to allow
    # you to declare class methods as commands. 
    def self.enable_plugin(klass)
      define_scope_accessors(klass)
      define_command_helpers(klass)
      define_command_annotations(klass)
      klass.class_eval do
        # Calls this with a block to define a plugin command:
        # 
        #   plugin_commands do
        #     key       "Ctrl+G"
        #     sensitive :tab_open
        #     def self.do_stuff
        #       ...
        #     end
        #   end
        def self.plugin_commands(scope="", &block)
          @__db_scope = self.to_s+"/" + scope
          self.start_defining_commands
          self.class_eval do 
            block.call
          end
          self.stop_defining_commands
        end

        def self.plugin_command(scope="")
          @__db_scope = self.to_s+"/" + scope
          self.start_defining_commands
          @one_command_only = true
        end
        
        def self.singleton_method_added(method_name) #:nodoc:
          if @defining_commands and !@aliasing
            @annotations ||= {}
            com           = InlineCommand.new
            com.name      = "#{__db_scope}/#{method_name}".gsub("//", "/")
            com.scope     = @annotations[:scope]
            com.sensitive = @annotations[:sensitive]
            com.block     = Proc.new { self.send(method_name) }
            com.inputs    = @annotations[:inputs]
            com.output    = @annotations[:output]
            com.record    = (@annotations[:record] == nil ? true : @annotations[:record])
            if @annotations[:key]
              com.key = @annotations[:key].split("/").last
              Keymap.register_key(@annotations[:key], com)
            end
            bus("/redcar/commands/#{com.name}").data = com
            if @annotations[:menu]
              MenuBuilder.item "menubar/"+@annotations[:menu], com.name
            end
            @aliasing = true
            if @aliasing
              newname = ("__defined_"+method_name.to_s).intern
              @aliasing = true
              metaclass.send(:alias_method, newname, method_name)
              metaclass.send(:define_method, method_name) do
                CommandHistory.record(com)
                CommandHistory.recording = false
                self.send(newname)
                CommandHistory.recording = true
              end
              @aliasing = false
            end
            @aliasing = false
            @annotations = nil
            stop_defining_commands if @one_command_only
          end
        end
      end
    end
  end
end
