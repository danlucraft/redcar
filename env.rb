$KCODE="U"
#
# The cucumber environment. Loads support env.rb files and step definition
# files from every plugin.
#

$:.push(File.expand_path("../lib", __FILE__))
$redcar_process_start_time = Time.now

require 'redcar'
Redcar.environment = :test
Redcar.load_unthreaded

Dir["plugins/*/features/support/*.rb"].each do |fn|
  require fn
end

Dir["plugins/*/features/step_definitions/*.rb"].each do |fn|
  require fn
end

Redcar::Top.start
