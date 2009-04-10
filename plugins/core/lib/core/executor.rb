module Redcar
  # This class executes Redcar commands. 
  class Executor
    def tab
      @tab
    end
    
    def doc
      @doc
    end
    
    def view
      @view
    end
    
    def set_tab(tab)
      @tab = tab
      if @tab.is_a? EditTab
        @doc = tab.document
        @view = tab.view
      end
    end
    
    def win
      Redcar::App.focussed_window
    end
    
    def initialize(command_instance, opts)
      @command_instance = command_instance
      @opts = opts
    end
    
    attr_reader :command_instance, :opts
    
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
      Redcar::Command.set_command_running(command_instance)
      begin
        tab = opts[:tab] || (Redcar::App.focussed_window.focussed_tab rescue nil)
        unless command_instance.respond_to? :execute or command_instance.class.pass?
          raise "Abstract Command Error"
        end 
        if tab
          set_tab(tab)
        end
        @output = nil
        begin
          if command_instance.class.pass?
            # TODO: think this needs more work. E.g., what happens during 
            # a macro if someone tries to execute a command? Won't their
            # event go on top of the event queue and bolsch up the macro?
            command_instance.gdk_event_key.put
            Gtk.main_iteration
          else
            if command_instance.method(:execute).arity > 0
              @output = command_instance.execute(input)
            else
              @output = command_instance.execute
            end
          end
          if opts[:replace_previous]
            CommandHistory.record_and_replace(command_instance)
          else
            CommandHistory.record(command_instance)
          end
        rescue Object => e
          Command.process_command_error(command_instance, e)
        end
        output_type = command_instance.class.get(:output)
        direct_output(output_type, @output) if @output and output_type
      rescue => e
        puts "[Redcar] error in command"
        puts e.message
        puts e.backtrace
      end
      Redcar::Command.set_command_stopped(command_instance)
      @output
    end
    
    # Gets the applicable input type, as a symbol. NOT the
    # actual input
    def valid_input_type
      if primary_input
        command_instance.class.get(:input)
      else
        command_instance.class.get(:fallback_input) || :document
      end
    end
    
    # Gets the primary input.
    def primary_input
      input = input_by_type(command_instance.class.get(:input))
      input == "" ? nil : input
    end
    
    # Gets the fallback input. Default is :document
    def secondary_input
      type = command_instance.class.get(:fallback_input) || :document
      input_by_type(type)
    end
    
    def input_by_type(type)
      App.log.info "input_by_type(#{type.inspect})"
      case type
      when :selected_text, :selection, :selectedText
        doc.selection
      when :document
        doc.text
      when :line
        doc.get_line
      when :word
        s = doc.cursor_iter.backward_symbol_start!.offset
        e = doc.cursor_iter.forward_symbol_end!.offset
        doc.text[s..e].rstrip.lstrip
      when :character
        doc.text[doc.cursor_iter.offset..doc.cursor_iter.offset]
      when :scope
        start_offset, end_offset = *doc.current_scope_range
        # puts "scope_range: #{start_offset}, #{end_offset}"
        if start_offset
          doc.text[start_offset...end_offset]
        end
      when :none, nil
        nil
      else
        raise "Unknown input type: #{type.inspect}"
      end
    end
    
    def input
      return nil unless tab
      if [:nothing, :none].include?(command_instance.class.get(:input))
        secondary_input
      else
        primary_input || secondary_input
      end
    end
    
    def direct_output(type, output_contents)
      if @status and @status >= 200 and @status <= 207
        type_map = {
          200 => :discard,
          201 => :replace_selected_text,
          202 => :replace_document,
          203 => :insert_as_text,
          204 => :insert_as_snippet,
          205 => :show_as_html,
          206 => :show_as_tool_tip,
          207 => :create_new_document
        }
        type = type_map[@status]
      end
      App.log.info "direct_output(#{type.inspect})"
      case type
      when :replace_document, :replaceDocument
        doc.text = output_contents
      when :replace_line, :replaceLine
        doc.replace_line(output_contents)
      when :replace_selected_text, :replaceSelectedText
        case valid_input_type
        when :selected_text, :selectedText, :selection
          doc.replace_selection(output_contents)
        when :line
          doc.replace_line(output_contents)
        when :document
          doc.text = output_contents
        when :word
          s = doc.cursor_iter.backward_symbol_start!.offset + 1
          e = doc.cursor_iter.forward_symbol_end!.offset + 1
          doc.replace_range(s, e, output_contents)
        when :scope
          start_offset, end_offset = *doc.current_scope_range
          doc.select(start_offset, end_offset)
          doc.replace_selection(output_contents)
          doc.cursor = (start_offset + end_offset)/2
        when :character
          doc.replace_range(doc.cursor_iter.offset, doc.cursor_iter.offset+1, output_contents)
        end
      when :insert_as_text, :insertAsText
        doc.insert_at_cursor(output_contents)
      when :insert_as_snippet, :insertAsSnippet
        delete_input
        doc.insert_as_snippet(output_contents, :indent => false)
      when :show_as_tool_tip, :show_as_tooltip, :showAsTooltip
        view.tooltip_at_cursor(output_contents.split("\n").map{|l| l.strip}.join("\n"))
      when :after_selected_text, :afterSelectedText
        if doc.selection?
          s, e = doc.selection_bounds
        else
          e = doc.cursor_offset
        end
        doc.insert(doc.iter(e), output_contents)
      when :create_new_document, :createNewDocument, :open_as_new_document
        # TODO: fix this hardcoded reference
        new_tab = Redcar.win.new_tab(Redcar::EditTab)
        new_tab.document.set_grammar_by_name(doc.parser.grammar.name)
        new_tab.document.text = output_contents
        new_tab.focus
      when :replace_input, :replaceInput
        case valid_input_type
        when :selected_text, :selectedText
          doc.replace_selection(output_contents)
        when :line
          doc.replace_line(output_contents)
        when :document
          doc.text = output_contents
        when :word
          doc.text[@s..@e] = output_contents
        when :scope
          start_offset, end_offset = *doc.current_scope_range
          doc.text[start_offset..end_offset] = output_contents
        end
      when :show_as_html, :showAsHTML
        show_as_html(output_contents.to_s)
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
      when :discard
      else
        raise "Unknown output type: #{type.inspect}"
      end
    end
    
    def show_as_html(html)
      html = html.gsub("tm-file:", "file:")
      # TODO: fix hardcoded reference to later plugin
      new_tab = Redcar.win.new_tab(Redcar::HtmlTab, html)
      new_tab.title = "output: " + command_instance.class.name
      new_tab.focus
    end
    
    def delete_input
      case valid_input_type
      when :selected_text, :selectedText
        doc.replace_selection("")
      when :line
        doc.delete_line
      when :document
        doc.text = ""
      when :word
        s = doc.cursor_iter.backward_symbol_start!.offset + 1
        e = doc.cursor_iter.forward_symbol_end!.offset + 1
        doc.replace_range(s, e, "")
      when :scope
        start_offset, end_offset = *doc.current_scope_range
        doc.text[start_offset..end_offset] = ""
      end
    end
  end
end
