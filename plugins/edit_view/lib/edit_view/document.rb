
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
    
    def_delegators :controller, 
                      :length, :line_count, :to_s, :text=,
                      :line_at_offset, :get_line, :offset_at_line,
                      :insert, :cursor_offset, :cursor_offset=,
                      :selection_range, :replace, :set_selection_range
    
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
    
    def cursor_line
      line_at_offset(cursor_offset)
    end
    
    def selection?
      selection_range.count > 0
    end
    
    def delete(offset, length)
      replace(offset, length, "")
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
