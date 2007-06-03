
require 'scripts/sensitivities'

Dir.glob("scripts/menus/*.rb").sort.each do |file|
  require file
end
