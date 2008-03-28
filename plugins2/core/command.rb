
module Redcar
  # Encapsulates a Redcar command. Commands wrap a block of Ruby code
  # with additional metadata to deal with command history recording and 
  # menus and keybindings. Define commands by subclassing the 
  # Redcar::Command class.
  #
  # === Examples
  #
  #   class CloseTab < Redcar::Command
  #     menu "File/Close"
  #     key "Global/Ctrl+W"
  #
  #     def execute(tab)
  #       tab.close if tab
  #     end
  #   end
  class Command
    extend FreeBASE::StandardPlugin
    
    class << self
      include Redcar::Sensitive
    end

    def self.start(plugin) #:nodoc:
      CommandHistory.clear
      plugin.transition(FreeBASE::RUNNING)
    end

    def self.stop(plugin) #:nodoc:
      CommandHistory.clear
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.inherited(klass)
      bus("/redcar/commands/#{klass}").data = klass
      @child_commands ||= []
      @child_commands << klass
#      puts ":inherited: #{klass} < #{self}"
      klass.update_operative
    end
    
    def self.child_commands
      @child_commands || []
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
    
    def self.process_command_error(name, e)
      puts "* Error in command: #{name}"
      puts "  trace:"
      puts e.to_s
      puts e.backtrace
    end
    
    def self.menu=(menu)
      @menu = menu
    end
    
    def self.menu(menu)
      @menu = menu
      MenuBuilder.item "menubar/"+menu, self.to_s
    end
    
    def self.get_menu
      @menu
    end
    
    def self.icon(icon)
      @icon = icon
    end
    
    def self.get_icon
      @icon
    end
    
    def self.key(key)
      @key = key
      Redcar::Keymap.register_key(key, self)
    end
    
    def self.get_key
      @key
    end
    
    def self.scope(scope)
      @scope = scope
    end
    
    def self.sensitive(sens)
      @sensitive ||= []
      @sensitive << sens
      Redcar::Sensitive.sensitize(self, sens)
    end
    
    def self.input(input)
      @input = inputs
    end
    
    def self.get(name)
      instance_variable_get(name)
    end
    
    def self.fallback_input(input)
      @fallback_input = input
    end
    
    def self.output(output)
      @output = output
    end
    
    def self.norecord
      @norecord = true
    end
    
    def self.norecord?
      @norecord
    end
    
    def self.active=(val)
      @sensitive_active = val
#      puts "#{self}.active = #{val.inspect}"
      update_operative
    end
    
    def self.update_operative
      old = @operative
      @operative = if active?
                     if self.ancestors[1].ancestors.include? Redcar::Command
                       self.ancestors[1].operative?
                     else
                       true
                     end
                   else
                     false
                   end
#      puts "com: #{self}: #{old.inspect} -> #{@operative.inspect}"
      if old != @operative and @menu
        Redcar::MenuDrawer.set_active(@menu, @operative)
      end
      child_commands.each(&:update_operative)
    end
    
    def self.operative?
      @operative == nil ? active? : @operative
    end
    
    def do(tab=Redcar::App.focussed_window.focussed_tab)
      unless self.respond_to? :execute
        raise "Abstract Command Error"
      end
      @output = nil
      begin
        case (a = self.method(:execute).arity)
        when 0
          @output = self.execute
        when 1
          @output = self.execute(tab)
        else
          raise "Unknown command arity error"
        end
        CommandHistory.record(self)
      rescue Object => e
        Command.process_command_error(self, e)
      end
      direct_output(self.class.get(:@output), @output) if @output
    end
    
    def record?
      !self.class.norecord?
    end
    
    # Gets the applicable input type, as a symbol. NOT the 
    # actual input
    def valid_input_type
      if primary_input
        self.class.get(:@input)
      else
        self.class.get(:@fallback_input)
      end
    end
    
    # Gets the primary input.
    def primary_input
      input = input_by_type(self.class.get(:@input))
      input == "" ? nil : input
    end
    
    def secondary_input
      input_by_type(self.class.get(:@fallback_input))
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
    
    def input
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
    
    def to_s
      self.class.to_s
    end
  end
  
  class ArbitraryCodeCommand < Command #:nodoc:
    norecord
    
    def initialize(&block)
      @block = block
    end
    
    def execute
      @block.call
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
      if recording and com.record?
        @history << com
      end
      prune
    end
    
    def self.prune #:nodoc:
      (@history.length - @max).times { @history.delete_at(0) }
    end
    
    # Clear the command history.
    def self.clear
      @history = []
    end
  end
  
end
