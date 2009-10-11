app_steps = File.dirname(__FILE__) + "/../../../application/features/step_definitions/*"
root = File.expand_path(File.dirname(__FILE__) + "/../../../../") + "/"
Dir[app_steps].each do |fn|
  require File.expand_path(fn).split(root).last
end