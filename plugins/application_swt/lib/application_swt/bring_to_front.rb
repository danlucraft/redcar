
gem "ffi"
require 'ffi'

module Redcar
  class ApplicationSWT
    class Window
        # it appears that swt offers no real way to
        # bring a window to the front
        # force_active doesn't seem to work as expected, at least on doze
        # http://stackoverflow.com/questions/2315560/how-do-you-force-a-java-swt-program-to-move-itself-to-the-foreground
        # this hack around seems to work for windows.
      module BringToFront
        extend FFI::Library
        ffi_lib 'user32', 'kernel32'
        ffi_convention :stdcall
        attach_function :GetForegroundWindow, [], :long
        attach_function :SetForegroundWindow, [:long], :int
        attach_function :GetWindowThreadProcessId, [:long, :pointer], :int
        attach_function :AttachThreadInput, [:int, :int, :int], :int
        attach_function :GetCurrentThreadId, [], :int # unused

        def self.bring_window_to_front hwnd_int
          wanted = hwnd_int
          top_window = BringToFront.GetForegroundWindow
          if top_window == 0
            # should be able to set it without delay?
            if(BringToFront.SetForegroundWindow(wanted) > 0)
              return true
            end
          end
          top_pid = BringToFront.GetWindowThreadProcessId(top_window, nil)
          wanted_pid = BringToFront.GetWindowThreadProcessId(hwnd_int, nil)
          if top_pid == wanted_pid
            if(BringToFront.SetForegroundWindow(wanted))
              return true
            end
          end
          if top_pid > 0 && wanted_pid > 0
            if (BringToFront.AttachThreadInput(wanted_pid,top_pid,1) == 0)
              return false
            end
            BringToFront.SetForegroundWindow(wanted) 
            BringToFront.AttachThreadInput(wanted_pid, top_pid,0)
            return true
          else
            return false
          end
        end
      end
    end
  end
end
