require 'java'
require "plugins/application_swt/lib/application_swt/swt_wrapper"


Swt::Widgets::Display.set_app_name "Ruby SWT Test"

display = Swt::Widgets::Display.new
shell = Swt::Widgets::Shell.new display
shell.setSize(450, 200)

layout = Swt::Layout::RowLayout.new
layout.wrap = true

shell.setLayout layout
shell.setText "Ruby SWT Test"

label = Swt::Widgets::Label.new(shell, Swt::SWT::CENTER)
label.setText "Ruby SWT Test"

Swt::Widgets::Button.new(shell, Swt::SWT::PUSH).setText("Test Button 1")

shell.pack
shell.open

while (!shell.isDisposed) do
  display.sleep unless display.readAndDispatch
end

display.dispose