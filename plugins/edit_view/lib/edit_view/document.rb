
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
                      :insert, :cursor_offset, :cursor_offset=
    
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
      @controllers[Controller::ModificationCallbacks].each do |controller|
        controller.after_modify
      end
      @controllers[Controller::NewlineCallback].each do |controller|
        if @change[2] == "\n"
          controller.after_newline(line_at_offset(@change[1]) + 1)
        end
      end
      @change = nil
    end
    
    private
    
    def update_from_mirror
      self.text        = mirror.read
      @edit_view.title = mirror.title
    end
  end
end
