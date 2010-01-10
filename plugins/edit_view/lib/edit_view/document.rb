
module Redcar
  # Each Redcar::Document is associated with an EditView, and has methods for
  # reading and modifying the contents of the EditView. Every document has a
  # Mirror of some resource.
  #
  # Events: new_mirror
  class Document
    include Redcar::Model
    include Redcar::Observable
    extend Forwardable
    
    def self.register_controller_type(controller_type)
      unless controller_type.ancestors.include?(Document::Controller)
        raise "expected #{Document::Controller}"
      end
      (@document_controller_types ||= []) << controller_type
    end
    
    class << self
      attr_accessor :default_mirror
      attr_reader :document_controller_types
    end
    
    attr_reader :mirror
    
    def initialize(edit_view)
      @edit_view = edit_view
      get_controllers
    end
    
    def get_controllers
      @controllers = {
        Controller::ModificationCallbacks => [],
        Controller::NewlineCallback => []
      }
      Document.document_controller_types.each do |type|
        @controllers.each do |key, value|
          if type.ancestors.include?(key)
            value << type.new(self)
          end
        end
      end
    end
    
    def save!
      @mirror.commit(to_s)
      set_modified(false)
    end
    
    def title
      @mirror ? @mirror.title : nil
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

    def verify_text(start_offset, end_offset, text)
      @change = [start_offset, end_offset, text]    
      @controllers[Controller::ModificationCallbacks].each do |controller|
        controller.before_modify(start_offset, end_offset, text)
      end
    end

    def modify_text
      start_offset, end_offset, text = *@change
      set_modified(true)
      @controllers[Controller::ModificationCallbacks].each do |controller|
        controller.after_modify
      end
      @controllers[Controller::NewlineCallback].each do |controller|
        if text == "\n"
          controller.after_newline(line_at_offset(start_offset) + 1)
        end
      end
      @change = nil      
      notify_listeners(:changed)
    end                  
    
    def about_to_be_changed(start_offset, length, text)
    end
    
    def changed(start_offset, length, text)
      notify_listeners(:changed)
    end
    
    def selection_range_changed(start_offset, end_offset)
      notify_listeners(:selection_range_changed, start_offset..end_offset)
    end
    
    # The line index the cursor is on (zero-based)
    #
    # @return [Integer]
    def cursor_line
      line_at_offset(cursor_offset)
    end
    
    # Is there any text selected? (Or equivalently, is the length
    # of the selection equal to 0)
    #
    # @return [Boolean]
    def selection?
      selection_range.count > 0
    end
    
    # Insert text
    #
    # @param [Integer] character offset from the start of the document
    # @param [String] text to insert
    def insert(offset, text)
      replace(offset, 0, text)
    end
    
    # Delete text
    #
    # @param [Integer] character offset from the start of the document
    # @param [Integer] length of text to delete
    def delete(offset, length)
      replace(offset, length, "")
    end

    # Replace text
    #
    # @param [Integer] character offset from the start of the document
    # @param [Integer] length of text to replace
    # @param [String] replacement text
    def replace(offset, length, text)
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
    # @param [String] new text
    def text=(text)
      controller.text = text
    end
    
    # Get the line index of the given offset
    #
    # @param [Integer] zero-based character offset
    # @return [Integer] zero-based index
    def line_at_offset(offset)
      controller.line_at_offset(offset)
    end
    
    # Get the character offset at the start of the given line
    #
    # @param [Integer] zero-based line index
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
    
    # Set the position of the cursor.
    #
    # @param [Integer] zero-based character offset
    def cursor_offset=(offset)
      controller.cursor_offset = offset
    end
    
    # The range of text selected by the user.
    #
    # @return [Range<Integer>] a range between two character offsets
    def selection_range
      controller.selection_range
    end
    
    # Set the range of text selected by the user.
    #
    # @param [Range<Integer>] a range between two character offsets
    def set_selection_range(range)
      controller.set_selection_range(range.begin, range.end)
    end
    
    # Get the text selected by the user. If no text is selected
    # returns "".
    #
    # @return [String]
    def selected_text
      get_range(selection_range.begin, selection_range.count)
    end
    
    # Get a range of text from the document.
    #
    # @param [String] the character offset of the start of the range
    # @param [String] the length of the string to get
    # @return [String] the text
    def get_range(start, length)
      controller.get_range(start, length)
    end

    # Get the text of a line by index. (Includes a trailing "\n", 
    # unless it is the last line in the document.)
    #
    # @param [Integer] the zero-based line number
    # @return [String] the text of the line
    def get_line(line_ix)
      controller.get_line(line_ix)
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
    
    # Get the offset at the end of a given line, *before* the newline character.
    #
    # @param [Integer] a zero-based line index
    def offset_at_inner_end_of_line(line_ix)
      if line_ix == line_count - 1
        length
      else
        offset_at_line(line_ix + 1) - 1
      end
    end
    
    private
    
    def update_from_mirror
      self.text        = mirror.read
      @modified = false
      @edit_view.title = title_with_star
    end
    
    def set_modified(boolean)
      @modified = boolean
      @edit_view.title = title_with_star
    end
    
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
  end
end
