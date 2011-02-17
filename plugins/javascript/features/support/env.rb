After do
  # Truncate the test file
  File.open(File.expand_path("../../fixtures/test.js", __FILE__), "w")
  @exceptions = 0
end

Before do
  @exceptions = 0
end

def add_exception(e)
  @exceptions = @exceptions + 1
  p e.message
end

def exception_count
  @exceptions
end