
module Redcar
  module Macros
    module Predictive
      class DocumentController
        include Redcar::Document::Controller
        
        def in_prediction
          @in_prediction = true
          yield
          @in_prediction = false
        end
        
        def after_action(action)
          unless @in_prediction
            @seq               = nil
            @sequence_finder   = nil
            @previous_sequence = nil
            Redcar.app.repeat_event(:end_prediction_mode)
          end
        end
        
        def in_prediction_mode?
          !!@seq
        end
        
        def sequence
          @seq ||= sequence_finder.next
        end
        
        def previous_sequence
          @previous_sequence
        end
        
        def next_sequence
          @seq = sequence_finder.next
        end
        
        def sequence_finder
          @sequence_finder ||= Predictive::SequenceFinder.new(document.edit_view.history)
        end

        def predict
          in_prediction do
            if sequence
              skip_length = (@previous_sequence == sequence) ? 0 : nil
              @previous_sequence = sequence
              sequence.run_in(document.edit_view, skip_length)
              Redcar.app.repeat_event(:start_prediction_mode)
            end
          end
        end
        
        def alternate_predict
          in_prediction do
            document.edit_view.undo
            next_sequence
            if sequence
              skip_length = (@previous_sequence == sequence) ? 0 : nil
              @previous_sequence = sequence
              sequence.run_in(document.edit_view, skip_length)
            end
          end
        end

      end
    end
  end
end
