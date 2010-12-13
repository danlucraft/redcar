After do
  # Truncate the test file
  File.open(File.expand_path("../../fixtures/test.js", __FILE__), "w")
end