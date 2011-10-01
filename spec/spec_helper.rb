puts "loading master spec_helper"

class RedcarSpecEnvironment
  def load_core
    $:.push File.expand_path("../../lib", __FILE__)
    require 'redcar'
    Redcar.environment = :test
    Redcar.no_gui_mode!
    Redcar.load_prerequisites
  end
  
  def spec_helpers
    spec_helpers = []
    RSpec.configuration.files_to_run.each do |spec_file|
      if spec_file =~ /plugins\/([^\/]+)\//
        filename = "plugins/#{$1}/spec/spec_helper"
        if File.exist?(filename + ".rb")
          spec_helpers << filename unless spec_helpers.include?(filename)
        end
      end
    end
    spec_helpers
  end
end

spec_environment = RedcarSpecEnvironment.new
spec_environment.load_core
spec_environment.spec_helpers.each do |spec_helper|
  puts "loading #{spec_helper}"
  require spec_helper
end



