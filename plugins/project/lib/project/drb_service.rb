module Redcar
  class Project
    class DrbService
      def initialize
        begin
          address = "druby://127.0.0.1:#{DRB_PORT}"
          @drb = DRb.start_service(address, self)
        rescue Errno::EADDRINUSE => e
          puts 'warning--not starting listener (perhaps theres another Redcar already open?)' + e + ' ' + address
        end
      end
    
      def open_item_untitled(path)
        begin
          puts 'drb opening untitled ' + full_path if $VERBOSE
          if File.file?(path)
            Swt.sync_exec do
              Project::Manager.open_untitled_path(path)
              Redcar.app.focussed_window.controller.bring_to_front
            end
          end
          'ok'
        rescue Exception => e
          puts 'drb got exception:' + e.class + " " + e.message, e.backtrace
          raise e
        end 
      end
      
      def open_item_drb(full_path)
        begin
          puts 'drb opening ' + full_path if $VERBOSE
          if File.directory? full_path
            Swt.sync_exec do
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
            Swt.sync_exec do
              if Redcar.app.windows.length == 0
                Project::Manager.restore_last_session
              end
              Redcar.app.focussed_window.controller.bring_to_front
            end
            'ok'
          elsif File.file?(full_path)
            Swt.sync_exec do
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

      def open_file_and_wait(file)
        semaphore = Mutex.new
        handler = nil
        tab = nil
        Swt.sync_exec do
          semaphore.lock
          Project::Manager.restore_last_session if Redcar.app.windows.empty?
          Project::Manager.open_file(file)
          window = Redcar.app.focussed_window
          window.controller.bring_to_front
          tab = window.focussed_notebook_tab
          handler = tab.add_listener(:close) { semaphore.unlock }
        end
        Thread.new(tab, handler) do
          semaphore.synchronize { tab.remove_listener(handler) }
        end.join # Wait until the tab's close event was fired
        'ok'
      rescue Exception => e
        puts 'drb got exception:' + e.class + " " + e.message, e.backtrace
        raise e
      end
      
    end
  end
end