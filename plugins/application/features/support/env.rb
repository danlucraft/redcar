require File.expand_path("../fake_event", __FILE__)

class TestingError < StandardError
end

def get_menu_name text
  Redcar::Menu.parse(text)
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

  def focussed_treebook_width
    Redcar.app.focussed_window.controller.treebook_width
  end

  def focussed_tree
    focussed_window.treebook.focussed_tree
  end

  def default_treebook_width
    Redcar.app.focussed_window.controller.default_treebook_width
  end

  def tree_with_title(title)
    focussed_window.treebook.trees.detect {|t| t.tree_mirror.title == title }
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
      items << item
      visible_tree_items(item, items) if item.expanded?
    end
    return items
  end

  def top_tree
    tree = focussed_tree.controller.viewer.get_tree
    tree.extend(TreeHelpers)
    tree
  end

  def find_node_with_text(top, node_text)
    node = top.detect { |node| node.text == node_text }
    return node if node
    all_children = top.map{ |node| node.children }.flatten
    find_node_with_text(all_children, node_text) unless all_children.empty?
  end

  def swt_label_for_item(vtabitem)
    vtablabel = vtabitem.instance_variable_get "@label"
    vtablabel.instance_variable_get "@label"
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
    @inputs = []
  end

  def set(method, value)
    @responses[method] = value
  end

  def should_get_message(message)
    @message = message
  end

  def should_get_popup_message(title,text)
    @popup_message = text
    @popup_title   = title
  end

  def should_get_popup_html(text)
    @popup_html = text
  end

  def popup_html(*args)
    unless @popup_text
      raise TestingError.new("got a popup html dialog with text #{@popup_html.inspect} where I didn't expect one")
    end
    unless @popup_text == args.first.inspect
      raise TestingError.new("expected text #{@popup_text.inspect}, got #{args.first.inspect}")
    end
  end

  def popup_text(*args)
    unless @popup_title and @popup_message
      raise TestingError.new("got a popup dialog titled #{@popup_title.inspect} with text #{@popup_message.inspect} where I didn't expect one")
    end
    unless @popup_title == args.first
      raise TestingError.new("expected title #{@popup_title.inspect}, got #{args.first.inspect}")
    end
    unless @popup_message == args[1]
      raise TestingError.new("expected text #{@popup_message.inspect}, got #{args[1].inspect}")
    end
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

  def input(*args)
    if @inputs.length < 1
      raise TestingError.new("No input added to complete this command.")
    end
    val = @inputs[0]
    @inputs.delete_at(0)
    {:value => val, :button => :ok}
  end

  def add_input(value)
    @inputs << value
  end

  def clear_input
    @inputs = []
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
  Swt.sync_exec do
    dialogs.each {|d| d.controller.model.close }
  end
  Redcar.app.windows.each do |win|
    if pr = Redcar::Project::Manager.in_window(win)
      Swt.sync_exec do
        pr.close
      end
    end
    win.treebook.trees.each do |tree|
      Swt.sync_exec do
        win.treebook.remove_tree(tree)
      end
    end
    win.notebooks.each do |notebook|
      while tab = notebook.tabs.first
        Swt.sync_exec do
          tab.close
        end
      end
    end
    while win.notebooks.length > 1
      Swt.sync_exec do
        win.close_notebook
      end
    end
  end
  while Redcar.app.windows.length > 1
    Swt.sync_exec do
      Redcar.app.windows.last.close
    end
  end
  Swt.sync_exec do
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
  Redcar.app.history.clear
  if errors.any?
    raise "Command errors #{errors.inspect}"
  end
  # total_mem = java.lang.Runtime.getRuntime.totalMemory
  # free_mem  = java.lang.Runtime.getRuntime.freeMemory
  # p [:total, total_mem/1000, :free, free_mem/1000, :diff, (total_mem - free_mem)/1000]
end

at_exit {
  FileUtils.rm_rf(Redcar::Plugin::Storage.storage_dir)
}
