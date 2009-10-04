app_steps = File.dirname(__FILE__) + "/../../../application/features/step_definitions/*"
Dir[app_steps].each do |fn|
  require fn
end