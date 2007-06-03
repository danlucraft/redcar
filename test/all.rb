
Dir.glob(File.dirname(__FILE__) + "/*_test.rb") do |file|
  p file
  require file unless file.include? "~"
end
