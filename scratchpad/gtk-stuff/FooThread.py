# Demo application showing how once can combine the python
# threading module with GObject signals to make a simple thread
# manager class which can be used to stop horrible blocking GUIs.
#
# (c) 2008, John Stowers <john.stowers@gmail.com>
#
# This program serves as an example, and can be freely used, copied, derived
# and redistributed by anyone. No warranty is implied or given.
import gtk
import gobject
gobject.threads_init()

import threading
import time
import random

class _IdleObject(gobject.GObject):
    """
    Override gobject.GObject to always emit signals in the main thread
    by emmitting on an idle handler
    """
    def __init__(self):
        gobject.GObject.__init__(self)

    def emit(self, *args):
        gobject.idle_add(gobject.GObject.emit,self,*args)

class _FooThread(threading.Thread, _IdleObject):
    """
    Cancellable thread which uses gobject signals to return information
    to the GUI.
    """
    __gsignals__ =  { 
            "completed": (
                gobject.SIGNAL_RUN_LAST, gobject.TYPE_NONE, []),
            "progress": (
                gobject.SIGNAL_RUN_LAST, gobject.TYPE_NONE, [
                gobject.TYPE_FLOAT])        #percent complete
            }

    def __init__(self, *args):
        threading.Thread.__init__(self)
        _IdleObject.__init__(self)
        self.cancelled = False
        self.data = args[0]
        self.name = args[1]
        self.setName("%s" % self.name)

    def cancel(self):
        """
        Threads in python are not cancellable, so we implement our own
        cancellation logic
        """
        self.cancelled = True

    def run(self):
        print "Running %s" % str(self)
        for i in range(self.data):
            if self.cancelled:
                break
            time.sleep(0.1)
            self.emit("progress", i/float(self.data)*100)            
        self.emit("completed")

class FooThreadManager:
    """
    Manages many FooThreads. This involves starting and stopping
    said threads, and respecting a maximum num of concurrent threads limit
    """
    def __init__(self, maxConcurrentThreads):
        self.maxConcurrentThreads = maxConcurrentThreads
        #stores all threads, running or stopped
        self.fooThreads = {}
        #the pending thread args are used as an index for the stopped threads
        self.pendingFooThreadArgs = []

    def _register_thread_completed(self, thread, *args):
        """
        Decrements the count of concurrent threads and starts any 
        pending threads if there is space
        """
        del(self.fooThreads[args])
        running = len(self.fooThreads) - len(self.pendingFooThreadArgs)

        print "%s completed. %s running, %s pending" % (
                            thread, running, len(self.pendingFooThreadArgs))

        if running < self.maxConcurrentThreads:
            try:
                args = self.pendingFooThreadArgs.pop()
                print "Starting pending %s" % self.fooThreads[args]
                self.fooThreads[args].start()
            except IndexError: pass

    def make_thread(self, completedCb, progressCb, userData,  *args):
        """
        Makes a thread with args. The thread will be started when there is
        a free slot
        """
        running = len(self.fooThreads) - len(self.pendingFooThreadArgs)

        if args not in self.fooThreads:
            thread = _FooThread(*args)
            #signals run in the order connected. Connect the user completed
            #callback first incase they wish to do something 
            #before we delete the thread
            thread.connect("completed", completedCb, userData)
            thread.connect("completed", self._register_thread_completed, *args)
            thread.connect("progress", progressCb, userData)
            #This is why we use args, not kwargs, because args are hashable
            self.fooThreads[args] = thread

            if running < self.maxConcurrentThreads:
                print "Starting %s" % thread
                self.fooThreads[args].start()
            else:
                print "Queing %s" % thread
                self.pendingFooThreadArgs.append(args)

    def stop_all_threads(self, block=False):
        """
        Stops all threads. If block is True then actually wait for the thread
        to finish (may block the UI) 
        """
        for thread in self.fooThreads.values():
            thread.cancel()
            if block:
                if thread.isAlive():
                    thread.join()

class Demo:
    def __init__(self):
        #build the GUI
        win = gtk.Window()
        win.connect("delete_event", self.quit)
        box = gtk.VBox(False,4)
        win.add(box)
        addButton = gtk.Button("Add Thread")
        addButton.connect("clicked",self.add_thread)
        box.pack_start(addButton,False,False)
        stopButton = gtk.Button("Stop All Threads")
        stopButton.connect("clicked",self.stop_threads)
        box.pack_start(stopButton,False,False)

        #display threads in a treeview
        self.pendingModel = gtk.ListStore(gobject.TYPE_STRING,gobject.TYPE_INT)
        self.completeModel = gtk.ListStore(gobject.TYPE_STRING)
        self._make_view(self.pendingModel, "Pending Threads", True, box)
        self._make_view(self.completeModel,"Completed Threads", False, box)

        #THE ACTUAL THREAD BIT
        self.manager = FooThreadManager(3)

        #Start the demo
        win.show_all()
        gtk.main()

    def _make_view(self, model, title, showProgress, vbox):
        view = gtk.TreeView(model)
        view.append_column(gtk.TreeViewColumn(title, gtk.CellRendererText(), text=0))
        if showProgress:
            view.append_column(gtk.TreeViewColumn("Progress", gtk.CellRendererProgress(), value=1))
        vbox.pack_start(view)

    def quit(self, sender, event):
        self.manager.stop_all_threads(block=True)
        gtk.main_quit()

    def stop_threads(self, *args):
        #THE ACTUAL THREAD BIT
        self.manager.stop_all_threads()

    def add_thread(self, sender):
        #make a thread and start it
        data = random.randint(20,60)
        name = "Thread #%s" % random.randint(0,1000)
        rowref = self.pendingModel.insert(0,(name,0)) 
        
        #THE ACTUAL THREAD BIT
        self.manager.make_thread(
                        self.thread_finished,
                        self.thread_progress,
                        rowref,data,name)

    def thread_finished(self, thread, rowref):
        self.pendingModel.remove(rowref)
        self.completeModel.insert(0,(thread.name,))

    def thread_progress(self, thread, progress, rowref):
        self.pendingModel.set_value(rowref,1,int(progress))

if __name__ == "__main__":
    demo = Demo()
