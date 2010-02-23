
require 'auto_pairer/document_controller'
require 'auto_pairer/pairs_for_scope'

module Redcar
  class AutoPairer
    def self.document_controller_types
      [AutoPairer::DocumentController]
    end
  end
end
