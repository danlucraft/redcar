module Redcar
  class Project
    class DrbService
      def initialize
        address = "druby://127.0.0.1:#{Redcar.drb_port}"
        Redcar.log.benchmark("start drb service") do
          @drb = DRb.start_service(address, self)
        end
      rescue Errno::EADDRINUSE => e
        puts 'warning--not starting listener (perhaps theres another Redcar already open?)' + e + ' ' + address
      end

      def open_item_drb(full_path, untitled = false, wait = false)
        puts %{drb opening #{"untitled" if untitled} #{full_path}} if $VERBOSE
        if File.directory? full_path
          Swt.sync_exec { open_directory(full_path) }
        elsif full_path == 'just_bring_to_front'
          Swt.sync_exec { bring_to_front }
        elsif File.file?(full_path)
          open_file(full_path, untitled, wait)
        end
        'ok'
      rescue Exception => e
        puts 'drb got exception:' + e.class + " " + e.message, e.backtrace
        raise e
      end

      # Opens the specified directory in a new window, if it was not
      # already open. Brings the project's window to the front, if this
      # directory is already opened. If the specified directory was the last open
      # directory, restores the complete session.
      def open_directory(full_path)
        if Redcar.app.windows.empty? and Application.storage['last_open_dir'] == full_path
          Project::Manager.restore_last_session
        end

        Redcar::Project.window_projects.each_pair do |window, project|
          return bring_window_to_front(window) if project.path == full_path
        end
        Project::Manager.open_project_for_path(full_path)
        bring_window_to_front
      end

      ## Focuses a Redcar window
      def bring_to_front
        Project::Manager.restore_last_session if Redcar.app.windows.empty?
        bring_window_to_front
      end
      
      def bring_window_to_front(win = Redcar.app.focussed_window)
        unless Redcar.environment == :test
          win.controller.bring_to_front
        end
      end

      # Opens a file, optionally untitled, and waits for it to close, if requested
      def open_file(file, untitled, wait)
        file_open_block = Proc.new do
          Project::Manager.restore_last_session if Redcar.app.windows.empty?
          if untitled
            Project::Manager.open_untitled_path(file)
          else
            Project::Manager.open_file(file)
          end
          bring_window_to_front
        end
        wait ? open_file_and_wait(&file_open_block) : Swt.sync_exec(&file_open_block)
      end

      def open_file_and_wait
        semaphore = Mutex.new
        handler = nil
        tab = nil
        Swt.sync_exec do
          semaphore.lock
          yield
          tab = Redcar.app.focussed_window.focussed_notebook_tab
          handler = tab.add_listener(:close) { semaphore.unlock }
        end
        Thread.new(tab, handler) do
          semaphore.synchronize { tab.remove_listener(handler) }
        end.join # Wait until the tab's close event was fired
      end
    end
  end
end