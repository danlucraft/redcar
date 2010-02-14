module Redcar
  class Project
    class DrbService
      def initialize
        # TODO choose a random port instead of hard coded
        begin
          address = "druby://127.0.0.1:9999"
          @drb = DRb.start_service(address, self)
        rescue Errno::EADDRINUSE => e
          puts 'warning--not starting listener (perhaps theres another Redcar already open?)' + e + ' ' + address
        end
      end
    
      # opens an item as if from the command line for use via drb
      def open_item_drb(full_path)
        begin
          puts 'drb opening ' + full_path if $VERBOSE
          if File.file? full_path
            
            Redcar::ApplicationSWT.sync_exec {            
              if Redcar.app.windows.length == 0              
                Project.restore_last_session
              end
              
              FileOpenCommand.new(full_path).execute
              Redcar.app.focussed_window.controller.bring_to_front          
            }
            'ok'
          elsif File.directory? full_path
            Redcar::ApplicationSWT.sync_exec {
            
              # open in any existing window that already has that dir open as a tree
              # else in a new window
              # open the window that already has this dir open
              if Redcar.app.windows.length == 0 && storage['last_open_dir'] == full_path
                Project.restore_last_session
              end
              
              if Redcar.app.windows.length > 0
                window = Redcar.app.windows.find{|win| 
                  # XXXX how can win be nil here?
                  win && win.treebook.trees.find{|t| 
                    t.tree_mirror.is_a?(Redcar::Project::DirMirror) && t.tree_mirror.path == full_path
                  }
                }            
              end               
              window ||= Redcar.app.new_window          
              Project.open_dir(full_path, window)
              Redcar.app.focussed_window.controller.bring_to_front
              
            }
            'ok'
          elsif full_path == 'just_bring_to_front'          
            Redcar::ApplicationSWT.sync_exec {
              if Redcar.app.windows.length == 0
                Project.restore_last_session
              end
              Redcar.app.focussed_window.controller.bring_to_front
            }
            'ok'
          else
            puts 'remote load: unexpected: file not found ' + full_path
            'fail'
          end
        rescue Exception => e
          # normally drb would swallow these
          puts 'drb got exception:' + e, e.backtrace
          raise e
        end 
      end
      
    end
  end
end
    