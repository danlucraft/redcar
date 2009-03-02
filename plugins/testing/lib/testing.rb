
# This plugin contains test runners for testing Redcar.
# Currently implemented:
#
#   * RSpec test runner, which looks for specs in plugin-dir/specs
#   * Cucumber runner, which looks for features in plugin-dir/features
#
# Usage:
#
#     Redcar::Testing::InternalRSpecRunner.spec_plugin("project")
#     Redcar::Testing::InternalCucumberRunner.features_plugin("project")
#
module Redcar::Testing
  def self.run_features
    if ix = Redcar::App.ARGV.index("--features-plugin")
      Redcar::Testing::InternalCucumberRunner.run_feature_for_plugin(Redcar::App.ARGV[ix+1])
      Redcar::App.quit
    elsif Redcar::App.ARGV.index("--features")
      Redcar::Testing::InternalCucumberRunner.run_all_features
      Redcar::App.quit
    end
  end
end
