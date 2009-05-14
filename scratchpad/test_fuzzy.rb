
def find_files(text, directories)
  files = []
  s = Time.now
  directories.each do |dir|
    files += Dir[File.expand_path(dir + "/**/*")]
  end
  puts "find files took: #{Time.now - s}"
  re = make_regex(text)
  
  score_match_pairs = []
  cutoff = 10000000
  s = Time.now
  count = 0
  results = files.each do |fn| 
    unless File.directory?(fn)
      bit = fn.split("/")
      if m = bit.last.match(re)
        count += 1
        cs = []
        diffs = 0
        m.captures.each_with_index do |_, i|
 	        cs << m.begin(i + 1)
          if i > 0
            diffs += cs[i] - cs[i-1]
          end
        end
        score = (cs[0] + diffs)*100 + bit.last.length
        if score < cutoff
          score_match_pairs << [score, fn]
          score_match_pairs.sort!
          if score_match_pairs.length == 21
            cutoff = score_match_pairs.last.first
            score_match_pairs.pop
          end
        end
  		end
		end
	end
	puts count
  r = score_match_pairs.map {|a| a.last }
  puts "score files took: #{Time.now - s}"
  r
end

def make_regex(text)
  re_src = "(" + text.split(//).map{|l| Regexp.escape(l) }.join(").*?(") + ")"
  Regexp.new(re_src)
end

s = Time.now
result = find_files("test", ["/home/dan/redcar/redcar/"])
puts "took #{Time.now - s}s"
# result.each do |file|
#   # puts file
#   
# end
  
