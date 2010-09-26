
module Redcar
  module Macros
    module Predictive
      class DocumentController
        include Redcar::Document::Controller
        
        def after_action(action)
          p [:after_action, action]
        end
        
        def sequence
          @seq ||= Predictive::SequenceFinder.new(document.edit_view.history).next
        end
      end
    end
  end
end
