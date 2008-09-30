
root = File.expand_path(File.dirname(__FILE__) + "/../")
files = Dir[File.expand_path(root + "/**/*")]
puts "#{files.length} files found"
puts "searching for '#{ARGV[0]}'"


start_time = Time.now

re_src = "(" + ARGV[0].split(//).join(").*?(") + ")"
puts "re source: #{re_src}"
re = Regexp.new(re_src)

results = files.map do |fn| 
  unless File.directory?(fn)
    if m = fn.split("/").last.match(re)
      [fn, m]
    end
  end
end

results = results.compact

results = results.map do |fn, m|
  cs = []
  diffs = 0
  m.captures.each_with_index do |_, i|
    cs << m.begin(i + 1)
    if i > 0
      diffs += cs[i] - cs[i-1]
    end
  end
  score = (cs[0] + diffs)*100 + fn.split("/").last.length
  [fn, score]
end
puts 
puts "Results: "
puts results.sort_by{|_, s| s}.map{|fn, m| "   " + fn.split("/").last.ljust(20) + "  " + m.inspect}
puts
puts "Took #{Time.now - start_time} seconds"
