
Dir.glob(File.expand_path("../../../../application/features/step_definitions/*", __FILE__)).each do |fn|
  require fn
end
