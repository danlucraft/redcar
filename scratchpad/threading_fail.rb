require 'gtk2'

class TreeStoreThreadingFail
  
  def initialize
    @ts = Gtk::TreeStore.new(String)
    make_iters
  end
  
  def make_iters
    10.times do |i|
      iter = @ts.append(nil)
      iter[0] = "created by #{Thread.current}: #{i}"
    end
  end
  
  def delete_iters
    while iter = @ts.iter_first
      @ts.remove(iter)
    end
  end
  
  def modify_iters
    @ts.each do |iter|
      iter[0] = "modified by #{Thread.current}: #{i}"
    end
  end
  
  def print_iters
    puts "Iters:"
    @ts.each do |iter|
      puts iter[0]
    end
    puts
  end
  
  def run
    Thread.new do
      loop do 
        make_iters
      end
    end
        
    Thread.new do
      loop do
        delete_iters
      end
    end
        
    Thread.new do
      loop do
        modify_iters
      end
    end
        
    Thread.new do
      loop do
        sleep 1
        print_iters
      end
    end
  end
end

win = Gtk::Window.new
button = Gtk::Button.new("Run")
button.signal_connect("clicked") do
  TreeStoreThreadingFail.new.run
  button.sensitive = false
end
win.add(button)
win.show_all
Gtk.main
