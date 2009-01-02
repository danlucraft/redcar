
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
  #     key "Ctrl+W"
  #
  #     def execute
  #       tab.close if tab
  #     end
  #   end
  class Command
    class << self
      include Redcar::Sensitive
    end

    def self.load
      Range.active ||= []
    end

    def self.start #:nodoc:
      CommandHistory.clear
    end

    def self.stop #:nodoc:
      CommandHistory.clear
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

    def self.icon(icon)
      @icon = icon
    end

    def self.key(key)
      @key = key
      Redcar::Keymap.register_key_command(key, self)
    end

    # Set the documentation string for this Command.
    def self.doc(val)
      @doc = val
    end

    # Set the range for this Command.
    def self.range(val)
      @range = val
      Range.register_command(val, self)
      update_operative
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
      @input = input
    end

    def self.get(name)
      instance_variable_get("@#{name}")
    end

    def self.set(name, val)
      instance_variable_set("@#{name}", val)
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
#      p @name
#      puts "#{self}.active = #{val.inspect}" if @name == "Help"
      update_operative
    end

    def self.update_operative
      old = @operative
#      puts "update_operative: #{self.inspect}" if @name == "Help"
#      puts "  #{!!active?}" if @name == "Help"
#      puts "  #{!!in_range?}" if @name == "Help"
      @operative = if active? and in_range?
                     if self.ancestors[1].ancestors.include? Redcar::Command
                       self.ancestors[1].operative?
                     else
                       true
                     end
                   else
                     false
                   end
#      puts "  com: #{self.inspect}: #{old.inspect} -> #{@operative.inspect}" if @name == "Help"
#      p self.inspect if @name == "Help"
      if old != @operative and @menu
#        p :updating_menu_sensitivity if @name == "Help"
        Redcar::MenuDrawer.set_active(@menu, @operative)
      end
      child_commands.each(&:update_operative)
    end

    def self.update_menu_sensitivity
      Redcar::MenuDrawer.set_active(@menu, @operative)
    end

    def self.in_range=(val)
      old = @in_range
#       p :in_range=
#         p self
#         p val
      @in_range = val
      update_operative
    end

    def self.nearest_range_ancestor
#       puts "nearest_range_ancestor: #{self.to_s.split("::").last}, #{@range.to_s.split("::").last}"
     r = if @range
        self
      elsif self.ancestors[1..-1].include? Redcar::Command
        self.ancestors[1].nearest_range_ancestor
      else
        nil
      end
#       if r
#         p r
#       else
#         p "nil range"
#       end
      r
    end

    def self.in_range?
      if nra = nearest_range_ancestor
        nra.get(:in_range)
      else
#         p self
#         p :global
        true # a command with no ranges set anywhere
             # in the hierarchy is a Window command
      end
    end

    def self.operative?
      @operative == nil ? active? : @operative
    end

    def self.correct_scope?(scope=nil)
      if @scope
        if !scope
          false
        else
          app = Gtk::Mate::Matcher.test_match(@scope, scope.hierarchy_names(true))
          if self.ancestors[1].ancestors.include? Redcar::EditTabCommand
            app and self.ancestors[1].correct_scope?(scope)
          else
            app
          end
        end
      else
        if self.ancestors[1].ancestors.include? Redcar::EditTabCommand
          self.ancestors[1].correct_scope?(scope)
        else
          true
        end
      end
    end

    def self.executable?(tab=nil)
      scope = nil
      scope = tab.document.cursor_scope if tab and tab.class <= EditTab
      o = operative?
      s = correct_scope?(scope)
#      e = (operative? and correct_scope?(scope))
      e = (o and s)
      e
    end

    attr :tab,  true
    attr :doc,  true
    attr :view, true

    def tab
      @__tab
    end
    
    def doc
      @__doc
    end
    
    def view
      @__view
    end

    def set_tab(tab)
      @__tab = tab
      if @__tab.is_a? EditTab
        @__doc = tab.document
        @__view = tab.view
      end
    end

    def win
      Redcar::App.focussed_window
    end

    def do(opts={})
      begin
        tab = opts[:tab] || (Redcar::App.focussed_window.focussed_tab rescue nil)
        unless self.respond_to? :execute
          raise "Abstract Command Error"
        end 
        if tab
          set_tab(tab)
        end
        @output = nil
        begin
          @output = self.execute
          if opts[:replace_previous]
            CommandHistory.record_and_replace(self)
          else
            CommandHistory.record(self)
          end
        rescue Object => e
          Command.process_command_error(self, e)
        end
        output_type = self.class.get(:output)
        direct_output(output_type, @output) if @output and output_type
      rescue => e
        puts "[Redcar] error in command"
        puts e.message
        puts e.backtrace
      end
      @output
    end

    def record?
      !self.class.norecord?
    end

    # Gets the applicable input type, as a symbol. NOT the
    # actual input
    def valid_input_type
      if primary_input
        self.class.get(:input)
      else
        self.class.get(:fallback_input)
      end
    end

    # Gets the primary input.
    def primary_input
      input = input_by_type(self.class.get(:input))
      input == "" ? nil : input
    end

    def secondary_input
      type = self.class.get(:fallback_input)
      return nil unless type
      input_by_type(type)
    end

    def input_by_type(type)
      puts "input_by_type(#{type.inspect})"
      case type
      when :selected_text, :selection, :selectedText
        doc.selection
      when :document
        doc.buffer.text
      when :line
        doc.get_line
      when :word
        if doc.cursor_iter.inside_word?
          s = doc.cursor_iter.backward_word_start!.offset
          e = doc.cursor_iter.forward_word_end!.offset
          doc.text[s..e].rstrip.lstrip
        end
      when :character
        doc.text[doc.cursor_iter.offset]
      when :scope
        start_offset, end_offset = *doc.current_scope_range
        puts "scope_range: #{start_offset}, #{end_offset}"
        if start_offset
          doc.text[start_offset...end_offset]
        end
      else
        raise "Unknown input type: #{type.inspect}"
      end
    end

    def input
      if [:nothing, :none].include?(self.class.get(:input))
        secondary_input
      else
        primary_input || secondary_input
      end
    end

    def direct_output(type, output_contents)
      puts "direct_output(#{type.inspect})"
      case type
      when :replace_document, :replaceDocument
        doc.replace output_contents
      when :replace_line, :replaceLine
        doc.replace_line(output_contents)
      when :replace_selected_text, :replaceSelectedText
        case valid_input_type
        when :selected_text, :selectedText
          doc.replace_selection(output_contents)
        when :line
          doc.replace_line(output_contents)
        when :document
          doc.replace output_contents
        when :word
          doc.text[@s..@e] = output_contents
        when :scope
          start_offset, end_offset = *doc.current_scope_range
          doc.select(start_offset, end_offset)
          doc.replace_selection(output_contents)
        end
      when :insert_as_text, :insertAsText
        doc.insert_at_cursor(output_contents)
      when :insert_as_snippet, :insertAsSnippet
        delete_input
        doc.insert_as_snippet(output_contents, :indent => false)
      when :show_as_tool_tip, :show_as_tooltip, :showAsTooltip
        view.tooltip_at_cursor(output_contents)
      when :after_selected_text, :afterSelectedText
        if doc.selected?
          s, e = doc.selection_bounds
        else
          e = doc.cursor_offset
        end
        doc.insert(e, output_contents)
      when :create_new_document, :createNewDocument
        # TODO: fix this hardcoded reference
        new_tab = Redcar.current_pane.new_tab(Redcar::EditTab)
        new_tab.name = "output: " + @name
        new_tab.doc.replace output_contents
        new_tab.focus
      when :replace_input, :replaceInput
        case valid_input_type
        when :selected_text, :selectedText
          doc.replace_selection(output_contents)
        when :line
          doc.replace_line(output_contents)
        when :document
          doc.replace output_contents
        when :word
          doc.text[@s..@e] = output_contents
        when :scope
          start_offset, end_offset = *doc.current_scope_range
          doc.text[start_offset..end_offset] = output_contents
        end
      when :show_as_html, :showAsHTML
        # TODO: fix hardcoded reference to later plugin
        new_tab = Redcar.win.new_tab(Redcar::HtmlTab, output_contents.to_s)
        new_tab.title = "output: " + self.class.name
        new_tab.focus
      when :insert_after_input, :insertAfterInput
        case valid_input_type
        when :selected_text, :selectedText
          s, e = doc.selection_bounds
          offset = [s, e].sort[1]
          doc.insert(offset, output_contents)
          doc.select(s+output_contents.length, e+output_contents.length)
        when :line
          if doc.cursor_line == doc.line_count-1
            doc.insert(doc.line_end(doc.cursor_line), "\n"+output_contents)
          else
            doc.insert(doc.line_start(doc.cursor_line+1), output_contents)
          end
        end
      else
        raise "Unknown output type: #{type.inspect}"
      end
    end

    def delete_input
      case valid_input_type
      when :selected_text, :selectedText
        doc.replace_selection("")
      when :line
        doc.delete_line
      when :document
        doc.replace ""
      when :word
        doc.text[@s..@e] = ""
      when :scope
        start_offset, end_offset = *doc.current_scope_range
        doc.text[start_offset..end_offset] = ""
      end
    end

    def to_s
      interesting_variables = instance_variables - %w(@__tab @__view @__doc @output)
      bits = interesting_variables.map do |iv|
        "#{iv}=" + instance_variable_get(iv.intern).inspect
      end
      self.class.to_s + " " + bits.join(", ")
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
    class << self
      attr_accessor(:tm_uuid, :bundle, :shell_script, :name)
    end

    def execute
      if current_scope = Redcar.doc.cursor_scope
        puts "current_scope #{current_scope.name}"
        puts "current_pattern #{current_scope.pattern.name}"
        App.set_environment_variables(Bundle.find_bundle_with_grammar(current_scope.pattern.grammar))
      end
      File.open("cache/tmp.command", "w") {|f| f.puts shell_script}
      File.chmod(0770, "cache/tmp.command")
      output, error = nil, nil
      Open3.popen3(shell_command) do |stdin, stdout, stderr|
        stdin.write(this_input = input)
        puts "input: #{this_input.inspect}"
        stdin.close
        output = stdout.read
        puts "output: #{output.inspect}"
        error = stderr.read
      end
      unless error.blank?
        puts "shell command failed with error:"
        puts error
      end
      output
    end

    def shell_script
      self.class.shell_script
    end

    def shell_command
      if shell_script[0..1] == "#!"
        "./cache/tmp.command"
      else
        "/bin/bash cache/tmp.command"
      end
    end
    
    def self.inspect
      "<# ShellCommand(#{get(:scope)}) #{name}>"
    end
    
#    def self.to_s
#      inspect
#    end
  end
end
