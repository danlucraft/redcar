
require 'auto_indenter/document_controller'

module Redcar
  class AutoIndenter
    
    def self.load
      Document.register_controller_type(AutoIndenter::DocumentController)
    end
  end
end

