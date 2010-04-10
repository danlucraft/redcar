module Redcar
  class Project
    class DrbService
      def initialize
        begin
          address = "druby://127.0.0.1:9999"
          @drb = DRb.start_service(address, self)
        rescue Errno::EADDRINUSE => e
          puts 'warning--not starting listener (perhaps theres another Redcar already open?)' + e + ' ' + address
        end
      end
    
      def open_item_drb(full_path)
        begin
          puts 'drb opening ' + full_path if $VERBOSE
          if File.directory? full_path
            Redcar::ApplicationSWT.sync_exec do
              if Redcar.app.windows.length == 0 and Application.storage['last_open_dir'] == full_path
                Project::Manager.restore_last_session
              end
              
              if Redcar.app.windows.length > 0
                window = Redcar.app.windows.find do |win| 
                  next unless win
                  win.treebook.trees.find do |t| 
                    t.tree_mirror.is_a?(Redcar::Project::DirMirror) and t.tree_mirror.path == full_path
                  end
                end        
              end
              Project::Manager.open_project_for_path(full_path)
              Redcar.app.focussed_window.controller.bring_to_front
            end
            'ok'
          elsif full_path == 'just_bring_to_front'          
            Redcar::ApplicationSWT.sync_exec do
              if Redcar.app.windows.length == 0
                Project::Manager.restore_last_session
              end
              Redcar.app.focussed_window.controller.bring_to_front
            end
            'ok'
          elsif File.file?(full_path)
            Redcar::ApplicationSWT.sync_exec do
              if Redcar.app.windows.length == 0
                Project::Manager.restore_last_session
              end
              Project::Manager.open_file(full_path)
              Redcar.app.focussed_window.controller.bring_to_front
            end
            'ok'            
          end
        rescue Exception => e
          puts 'drb got exception:' + e.class + " " + e.message, e.backtrace
          raise e
        end 
      end
      
    end
  end
end