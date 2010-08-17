class TestingError < StandardError
end

module SwtHelper
  def main_menu
    display = Redcar::ApplicationSWT.display
    shell   = display.get_shells.to_a.first
    menu_bar = shell.get_menu_bar
    menu_bar
  end
  
  def first_shell
    Redcar::ApplicationSWT.display.get_shells.to_a.first
  end
  
  def active_shell
    focussed_window.controller.shell
  end

  def focussed_window
    Redcar.app.focussed_window
  end

  def focussed_tree
    focussed_window.treebook.focussed_tree
  end
  
  def dialog(type)
    dialogs.detect {|d| d.is_a?(type) }
  end
  
  def dialogs
    Redcar::ApplicationSWT.display.get_shells.to_a.map do |s| 
      Redcar::ApplicationSWT.shell_dialogs[s]
    end.compact
  end

  def visible_tree_items(tree, items = [])
    tree.getItems.to_a.each do |item|
      items << item.getText
      visible_tree_items(item, items) if item.expanded?
    end
    return items
  end

  def top_tree
    tree = focussed_tree.controller.viewer.get_tree
    tree.extend(TreeHelpers)
    tree
  end
  
  module TreeHelpers
    def items
      getItems.to_a
    end
    
    def item_texts
      getItems.to_a.map {|item| item.getText}
    end
  end
end
    
class FakeDialogAdapter
  def initialize
    @responses = {}
  end
  
  def set(method, value)
    @responses[method] = value
  end
  
  def should_get_message(message)
    @message = message
  end
  
  def open_file(*args)
    check_for_raise(@responses[:open_file])
  end
  
  def open_directory(*args)
    check_for_raise(@responses[:open_directory])
  end
  
  def save_file(*args)
    check_for_raise(@responses[:save_file])
  end
  
  def message_box(*args)
    if @message == :any
    elsif @message
      unless @message == args.first
        raise TestingError.new("expected the message #{@message.inspect} got #{args.first.inspect}")
      end
      @message = nil
    else
      raise TestingError.new("got a message box showing #{args.first.inspect} when I didn't expect one")
    end
    @responses[:message_box].to_sym if @responses[:message_box]
  end
  
  def check_for_raise(result)
    if result == :raise_error
      raise TestingError.new("did not expect dialog")
    end
    result
  end
  
  def available_message_box_button_combos
    Redcar::ApplicationSWT::DialogAdapter.new.available_message_box_button_combos
  end
  
  def available_message_box_types
    Redcar::ApplicationSWT::DialogAdapter.new.available_message_box_types
  end
end

World(SwtHelper)

def close_everything
  Redcar.app.task_queue.cancel_all
  Redcar::ApplicationSWT.sync_exec do
    dialogs.each {|d| d.controller.model.close }
  end
  Redcar.app.windows.each do |win|
    while tree = win.treebook.trees.first
      Redcar::ApplicationSWT.sync_exec do
        win.treebook.remove_tree(tree)
      end
    end
    win.notebooks.each do |notebook|
      while tab = notebook.tabs.first
        Redcar::ApplicationSWT.sync_exec do
          tab.close
        end
      end
    end
    if win.notebooks.length == 2
      Redcar::ApplicationSWT.sync_exec do
        win.close_notebook
      end
    end
  end
  while Redcar.app.windows.length > 1
    Redcar::ApplicationSWT.sync_exec do
      Redcar.app.windows.last.close
    end
  end
  Redcar::ApplicationSWT.sync_exec do
    Redcar.app.focussed_window.close_speedbar if Redcar.app.focussed_window.speedbar
    Redcar.app.windows.first.title = Redcar::Window::DEFAULT_TITLE
  end
end

Before do
  close_everything
  Redcar::ApplicationSWT::FilterListDialogController.test_mode = true
  Redcar.gui.register_dialog_adapter(FakeDialogAdapter.new)
end

After do
  close_everything
  errors = Redcar.app.history.select {|command| command.error }
  if errors.any?
    raise "Command errors #{errors.inspect}"
  end
  Redcar.app.history.clear
end

at_exit {
  FileUtils.rm_rf(Redcar::Plugin::Storage.storage_dir)
}


