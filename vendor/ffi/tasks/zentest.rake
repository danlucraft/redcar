if HAVE_ZENTEST

# --------------------------------------------------------------------------
if test(?e, PROJ.test.file) or not PROJ.test.files.to_a.empty?
require 'autotest'

namespace :test do
  task :autotest do
    Autotest.run
  end
end

desc "Run the autotest loop"
task :autotest => 'test:autotest'

end  # if test

# --------------------------------------------------------------------------
if HAVE_SPEC_RAKE_SPECTASK and not PROJ.spec.files.to_a.empty?
require 'autotest/rspec'

namespace :spec do
  task :autotest do
    load '.autotest' if test(?f, '.autotest')
    Autotest::Rspec.run
  end
end

desc "Run the autotest loop"
task :autotest => 'spec:autotest'

end  # if rspec

end  # if HAVE_ZENTEST

# EOF
