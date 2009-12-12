# Demo application showing how once can combine the Ruby
# threading module with GObject signals to make a simple thread
# manager class which can be used to stop horrible blocking GUIs.
#
# (c) 2009, ported to Ruby by Daniel Lucraft <dan@fluentradical.com>
# (c) 2008, John Stowers <john.stowers@gmail.com>
#
# This program serves as an example, and can be freely used, copied, derived
# and redistributed by anyone. No warranty is implied or given.

require 'gtk2'

# Cancellable thread which uses gobject signals to return information
# to the GUI.
class FooThread < GLib::Object
  type_register
  
  signal_new("completed",    # name
    GLib::Signal::RUN_LAST, # flags
    nil,                     # accumulator (XXX: not supported yet)
    nil                     # return type (void == nil) 
      # parameter types
    )
      
  signal_new("progress",    # name
    GLib::Signal::RUN_LAST, # flags
    nil,                     # accumulator (XXX: not supported yet)
    nil,                     # return type (void == nil) 
    Float # parameter types
  )
  
  def initialize(data, name)
    @data, @name = args[0], args[1]
  end
  
  def run
    print "Running #{self}"
    0.upto(data) do |i|
      sleep 0.1
      emit("progress", i.to_f/data*100)
    end
    emit("completed")
  end
  
  # Override gobject.GObject to always emit signals in the main thread
  # by emmitting on an idle handler
  def emit(*args)
    Gtk.idle_add do
      super
    end
  end
end

# Manages many FooThreads. This involves starting and stopping
# said threads, and respecting a maximum num of concurrent threads limit
class FooThreadManager
  def initialize(max_concurrent_threads)
    @max_concurrent_threads = max_concurrent_threads
    @foo_threads = {}
    @threads = []
    @pending_foo_thread_args = []
  end

  # Decrements the count of concurrent threads and starts any 
  # pending threads if there is space
  def register_thread_completed(foo_thread, *args)
    @foo_threads.delete(args)
    running = @foo_threads.length - @pending_foo_thread_args.length
    pending = @pending_foo_thread_args.length
    puts "#{foo_thread} completed. #{running} running, #{pending} pending"
    
    if running < @max_concurrent_threads
      args = @pending_foo_thread_args.shift
      puts "Starting pending #{args.inspect}"
      @threads << Thread.new { @foo_threads[args].run }
    end
  end

  # Makes a thread with args. The thread will be started when there is
  # a free slot
  def make_thread(completed_cb, progresscb, user_data, *args)
    running = @foo_threads.length - @pending_foo_thread_args.length
    
    unless @foo_threads.include? args
      foo_thread = FooThread.new(*args)
      foo_thread.signal_connect("completed", user_data, &completed_cb)
      foo_thread.signal_connect("completed") do ||
        _register_thread_completed(foo_thread, *args)
      end
      foo_thread.signal_connect("progress", user_data, &progress_cb)
      @foo_threads[args] = foo_thread
      
      if running < @max_concurrent_threads
        puts "Starting #{foo_thread}"
        @threads << Thread.new { @foo_threads[args].run }
      else
        puts "Queuing #{foo_thread}"
        @pending_foo_thread_args.append(args)
      end
    end
  end

  # Stops all threads. If block is True then actually wait for the thread
  # to finish (may block the UI) 
  def stop_all_threads(block=false)
    @threads.each do |thread|
      thread.terminate
    end
  end
end

class Demo
  def initialize
end

Gdk::Threads.init


