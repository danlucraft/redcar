module Redcar
  # This class controls access to the document text in an edit tab. 
  # There are methods to read, modify and register listeners
  # for the document.
  class Document
    include Redcar::Model
    include Redcar::Observable
    extend Forwardable
    
    def self.all_document_controller_types
      result = []
      Redcar.plugin_manager.objects_implementing(:document_controller_types).each do |object|
        result += object.document_controller_types
      end
      result
    end
    
    class << self
      attr_accessor :default_mirror
    end
    
    attr_reader :mirror, :edit_view
    
    def initialize(edit_view)
      @edit_view = edit_view
      @grammar = Redcar::Grammar.new(self)
      get_controllers
    end
    
    def get_controllers
      @controllers = {
        Controller::ModificationCallbacks => [],
        Controller::NewlineCallback       => [],
        Controller::CursorCallbacks       => []
      }
      Document.all_document_controller_types.each do |type|
        controller = type.new
        controller.document = self
        @controllers.each do |key, value|
          if controller.is_a?(key)
            value << controller
          end
        end
      end
    end
    
    def controllers(klass)
      @controllers.values.flatten.uniq.select {|c| c.is_a?(klass) }
    end
    
    def save!
      @mirror.commit(to_s)
      @edit_view.reset_last_checked
      set_modified(false)
    end
    
    def modified?
      @modified
    end
    
    def title
      @mirror ? @mirror.title : nil
    end
    
    # helper method to get the mirror's path if it has one
    def path
      if @mirror and @mirror.respond_to?(:path) and @mirror.path
        @mirror.path
      else
        nil
      end
    end
    
    def exists?
      edit_view.exists?
    end
    
    def mirror=(new_mirror)
      notify_listeners(:new_mirror, new_mirror) do
        @mirror = new_mirror
        mirror.add_listener(:change) do
          update_from_mirror
        end
        update_from_mirror
      end
    end
    
    def mirror_changed?
      mirror and mirror.changed?
    end

    def verify_text(start_offset, end_offset, text)
      @change = [start_offset, end_offset, text]    
      @controllers[Controller::ModificationCallbacks].each do |controller|
        rescue_document_controller_error(controller) do
          controller.before_modify(start_offset, end_offset, text)
        end
      end
    end

    def modify_text
      start_offset, end_offset, text = *@change
      set_modified(true)
      @controllers[Controller::ModificationCallbacks].each do |controller|
        rescue_document_controller_error(controller) do
          controller.after_modify
        end
      end
      @controllers[Controller::NewlineCallback].each do |controller|
        if text == line_delimiter
          rescue_document_controller_error(controller) do
            controller.after_newline(line_at_offset(start_offset) + 1)
          end
        end
      end
      @change = nil      
      notify_listeners(:changed)
    end
    
    def cursor_moved(new_offset)
      @controllers[Controller::CursorCallbacks].each do |controller|
        rescue_document_controller_error(controller) do
          controller.cursor_moved(new_offset)
        end
      end
    end               
    
    def about_to_be_changed(start_offset, length, text)
    end
    
    def changed(start_offset, length, text)
      notify_listeners(:changed)
    end
    
    def selection_range_changed(start_offset, end_offset)
      notify_listeners(:selection_range_changed, start_offset..end_offset)
    end
    
    def single_line?
      controller.single_line?
    end
    
    # Returns the line delimiter for this document. Either
    # \n or \r\n. It will attempt to detect the delimiter from the document
    # or it will default to the platform delimiter.
    #
    # @return [String]
    def line_delimiter
      controller.get_line_delimiter
    end

    alias :delim :line_delimiter 
    
    # Is there any text selected? (Or equivalently, is the length
    # of the selection equal to 0)
    #
    # @return [Boolean]
    def selection?
      selection_range.count > 0
    end
    
    # Insert text
    #
    # @param [Integer] offset  character offset from the start of the document
    # @param [String] text  text to insert
    def insert(offset, text)
      return unless text and offset
      text = text.gsub(delim, "") if single_line?
      replace(offset, 0, text)
    end
    
    # Insert text at the cursor offset
    #
    # @param [String] text  text to insert
    def insert_at_cursor(text)
      insert(cursor_offset, text)
    end
    
    # Delete text
    #
    # @param [Integer] offset  character offset from the start of the document
    # @param [Integer] length  length of text to delete
    def delete(offset, length)
      replace(offset, length, "")
    end

    # Replace text
    #
    # @param [Integer] offset  character offset from the start of the document
    # @param [Integer] length  length of text to replace
    # @param [String] text  replacement text
    def replace(offset, length, text)
      text = text.gsub(delim, "") if single_line?
      controller.replace(offset, length, text)
    end
    
    # Length of the document in characters
    #
    # @return [Integer]
    def length
      controller.length
    end
    
    # Number of lines.
    #
    # @return [Integer]
    def line_count
      controller.line_count
    end
    
    # The entire contents of the document
    #
    # @return [String]
    def to_s
      controller.to_s
    end
    
    # Set the contents of the document
    #
    # @param [String] text  new text
    def text=(text)
      controller.text = text
    end    
	
    def controller_text
      controller.text
    end
    
    # Get the line index of the given offset
    #
    # @param [Integer] offset zero-based character offset
    # @return [Integer] zero-based index
    def line_at_offset(offset)
      controller.line_at_offset(offset)
    end
    
    # Get the character offset at the start of the given line
    #
    # @param [Integer] line   zero-based line index
    # @return [Integer] zero-based character offset
    def offset_at_line(line)
      controller.offset_at_line(line)
    end
    
    # Get the position of the cursor.
    #
    # @return [Integer] zero-based character offset
    def cursor_offset
      controller.cursor_offset
    end
    
    def cursor_line_offset
      cursor_offset - offset_at_line(cursor_line)
    end
    
    # Set the position of the cursor.
    #
    # @param [Integer] offset   zero-based character offset
    def cursor_offset=(offset)
      controller.cursor_offset = offset
    end
    
    # The line index the cursor is on (zero-based)
    #
    # @return [Integer]
    def cursor_line
      line_at_offset(cursor_offset)
    end
    
    def cursor_line_start_offset
      offset_at_line(cursor_line)
    end
    
    def cursor_line_end_offset
      offset_at_line_end(cursor_line)
    end
    
    def offset_at_line_end(line_ix)
      if line_ix == line_count - 1
        end_offset = length
      else
        end_offset = offset_at_line(line_ix + 1)
      end
    end
    
    def word
      @grammar.word
    end

    # The word at an offset.
    #
    # @param [Integer] an offset
    # @return [String] the text of the word
    def word_at_offset(offset)
      range = word_range_at_offset(offset)
      get_range(range.first, range.last - range.first)
    end
    
    # The word found at the current cursor offset.
    #
    # @return [String] the text of the word
    def current_word
      word_at_offset(cursor_offset)
    end
    
    # The range of the word at an offset.
    #
    # @param [Integer] an offset
    # @return [Range<Integer>] a range between two character offsets
    def word_range_at_offset(offset)
      line_ix = line_at_offset(offset)      
      match_left = offset == 0 ? false : !/\s/.match(get_slice(offset - 1, offset))
      match_right = offset == length ? false : !/\s/.match(get_slice(offset, offset + 1))
      if match_left && match_right
        match_word_around(offset)
      elsif match_left
        match_word_left_of(offset)
      elsif match_right
        match_word_right_of(offset)
      else
        offset..offset
      end
    end
    
    # Returns the range of the word located around an offset.
    # Before using this method, it's best to make sure there actually
    # might be a word around the offset. This means we are not at the beginning
    # or end of the file and there are no spaces left and right from the offset.
    #
    # @param [Integer] an offset
    # @return [Range<Integer>] a range between two character offsets
    def match_word_around(offset)
      line_index = line_at_offset(offset)
      line_end_offset = offset_at_line_end(line_index)
      right = 0
      matched_offsets = offset..offset
      until false
        new_match = match_word_left_of(offset + right)
        if new_match.last - new_match.first > matched_offsets.last - matched_offsets.first && new_match.first <= offset
          matched_offsets = new_match
        end
        right += 1
        if offset + right == length + 1 || /\s/.match(get_slice(offset, offset + right))
          break
        end
      end
      matched_offsets
    end
    
    # Returns the range of the word located left of an offset.
    # Before using this method, it's best to make sure there actually
    # might be a word left of the offset. This means we are not at the beginning
    # of the file and there are no spaces left of the offset.
    #
    # @param [Integer] an offset
    # @return [Range<Integer>] a range between two character offsets
    def match_word_left_of(offset)
      line_index = line_at_offset(offset)
      line_start_offset = offset_at_line(line_index)
      left = -1
      matched_left = false
      matched_offsets = offset..offset
      until offset + left == line_start_offset - 1 || /\s/.match(get_slice(offset + left, offset))
        current_offsets = offset + left..offset
        if word.match(get_slice(current_offsets.first, current_offsets.last))
          matched_offsets = current_offsets
          matched_left = true
        elsif matched_left
          break
        end
        left -= 1
      end
      matched_offsets
    end
    
    # Returns the range of the word located right of an offset.
    # Before using this method, it's best to make sure there actually
    # might be a word right of the offset. This means we are not at the end of 
    # the file and there are no spaces right of the offset.
    #
    # @param [Integer] an offset
    # @return [Range<Integer>] a range between two character offsets
    def match_word_right_of(offset)
      line_index = line_at_offset(offset)
      line_end_offset = offset_at_line_end(line_index)
      right = 0
      matched_offsets = offset..offset
      until offset + right == length + 1 || /\s/.match(get_slice(offset, offset + right))
        if word.match(get_slice(offset, offset + right))
          matched_offsets = offset..offset + right
        end
        right += 1
      end
      matched_offsets
    end
    
    # The range of the word at the current cursor position.
    #
    # @return [Range<Integer>] a range between two character offsets
    def current_word_range
      word_range_at_offset(cursor_offset)
    end
    
    # The range of text selected by the user.
    #
    # @return [Range<Integer>] a range between two character offsets
    def selection_range
      controller.selection_range
    end

    # The ranges of text selected by the user.
    #
    # @return [Range<Integer>] a range between two character offsets
    def selection_ranges
      controller.selection_ranges
    end
    
    def selection_offset
      controller.selection_offset
    end
    
    def selection_line
      line_at_offset(selection_offset)
    end
    
    # Set the range of text selected by the user. 
    #
    # @param [Integer] cursor_offset
    # @param [Integer] selection_offset
    def set_selection_range(cursor_offset, selection_offset)
      controller.set_selection_range(cursor_offset, selection_offset)
    end
    
    # Select all text in the document.
    def select_all
      set_selection_range(length, 0)
    end
    
    # Get the text selected by the user. If no text is selected
    # returns "".
    #
    # @return [String]
    def selected_text
      get_range(selection_range.begin, selection_range.count)
    end
    
    # Is the document in block selection mode.
    def block_selection_mode?
      controller.block_selection_mode?
    end
    
    # Turn the block selection mode on or off.
    def block_selection_mode=(boolean)
      controller.block_selection_mode = !!boolean
    end
    
    # Get a range of text from the document.
    #
    # @param [Integer] start  the character offset of the start of the range
    # @param [Integer] length  the length of the string to get
    # @return [String] the text
    def get_range(start, length)
      controller.get_range(start, length)
    end
    
    # Get a slice of text from the document.
    #
    # @param [Integer] start_offset the character offset of the start of the slice
    # @param [Integer] end_offset   the character offset of the end of the slice
    # @return [String] the text
    def get_slice(start_offset, end_offset)
      get_range(start_offset, end_offset - start_offset)
    end

    # Get the text of a line by index. (Includes a trailing "\n", 
    # unless it is the last line in the document.)
    #
    # @param [Integer] line_ix  the zero-based line number
    # @return [String] the text of the line
    def get_line(line_ix)
      controller.get_range(
        offset_at_line(line_ix),
        offset_at_line_end(line_ix) - offset_at_line(line_ix)
      )
    end
    
    # Get all text
    def get_all_text
      get_range(0, length)
    end
    
    # Replace a line in the document. This has two modes. In the first, 
    # you supply the replacement text as an argument:
    #
    #     replace_line(10, "new line text")
    #
    # In the second, you supply a block. The block argument is the current
    # text of the line, and the return value of the block is the 
    # replacement text:
    #
    #     replace_line(10) {|current_text| current_text.upcase }
    def replace_line(line_ix, text=nil)
      text ||= yield(get_line(line_ix))
      start_offset = offset_at_line(line_ix)
      end_offset   = offset_at_inner_end_of_line(line_ix)
      replace(start_offset, end_offset - start_offset, text)
    end
    
    # Get the offset at the end of a given line, *before* the line delimiter.
    #
    # @param [Integer] line_ix  a zero-based line index
    def offset_at_inner_end_of_line(line_ix)
      if line_ix == line_count - 1
        length
      else
        offset_at_line(line_ix + 1) - delim.length
      end
    end
    
    # Does the minimum amount of scrolling that brings the given line 
    # into the viewport. Which may be none at all.
    #
    # @param [Integer] line_ix  a zero-based line index
    def scroll_to_line(line_ix)
      if line_ix > biggest_visible_line
        top_line_ix = smallest_visible_line + (line_ix - biggest_visible_line) + 2
        top_line_ix = [top_line_ix, line_count - 1].min
        scroll_to_line_at_top(top_line_ix)
      elsif line_ix < smallest_visible_line
        bottom_line_ix = line_ix - 2
        bottom_line_ix = [bottom_line_ix, 0].max
        scroll_to_line_at_top(bottom_line_ix)
      end
    end
    
    # Tries to scroll so the given line is at the top of the viewport.
    #
    # @param [Integer] line_ix  a zero-based line index
    def scroll_to_line_at_top(line_ix)
      @edit_view.controller.scroll_to_line(line_ix)
    end

    # The line_ix of the line at the top of the viewport.
    #
    # @return [Integer] a zero-based line index    
    def smallest_visible_line
      @edit_view.controller.smallest_visible_line
    end
    
    # The line_ix of the line at the bottom of the viewport.
    #
    # @return [Integer] a zero-based line index    
    def biggest_visible_line
      @edit_view.controller.biggest_visible_line
    end

    def ensure_visible(offset)
      @edit_view.controller.ensure_visible(offset)
    end

    def num_lines_visible
      biggest_visible_line - smallest_visible_line
    end
    
    # The scope hierarchy at this point
    #
    # @param [String]
    def cursor_scope
      controller.scope_at(cursor_line, cursor_line_offset)
    end
    
    def create_mark(offset, gravity=:right)
      controller.create_mark(offset, gravity)
    end
    
    def delete_mark(mark)
      controller.delete_mark(mark)
    end
    
    # Everything within the block will be treated as a single action
    # for the purposes of Undo.
    #
    #     doc.compound { first_thing; second_thing }
    def compound
      @edit_view.controller.compound { yield }
    end
    
    def update_from_mirror
      previous_line      = cursor_line
      top_line           = smallest_visible_line
      
      self.text          = mirror.read
      
      @modified          = false
      @edit_view.title   = title_with_star
      if line_count > previous_line
        self.cursor_offset = offset_at_line(previous_line)
        scroll_to_line_at_top(top_line)
      end
    end
       
    def set_modified(boolean)
      @modified = boolean
      @edit_view.title = title_with_star
    end
 
    def indentation
      Document::Indentation.new(self, @edit_view.tab_width, @edit_view.soft_tabs?)
    end
 
    private 
   
    def title_with_star
      if mirror
        if @modified
          "*" + mirror.title
        else
          mirror.title
        end
      else
        "untitled"
      end
    end
    
    def rescue_document_controller_error(controller)
      begin
        yield
      rescue => e
        puts "*** ERROR in Document controller: #{controller.inspect}"
        puts e.class.name + ": " + e.message
        puts e.backtrace
      end   
    end
  end
end
