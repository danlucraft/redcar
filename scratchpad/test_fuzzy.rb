
def find_files(text, directories)
  files = []
  directories.each do |dir|
    files += Dir[File.expand_path(dir + "/**/*")]
  end
  
  re = make_regex(text)
  
  score_match_pairs = []
  max = 10000000
  
  results = files.each do |fn| 
    unless File.directory?(fn)
      bit = fn.split("/")
      if m = bit.last.match(re)
        cs = []
        diffs = 0
        m.captures.each_with_index do |_, i|
 	        cs << m.begin(i + 1)
          if i > 0
            diffs += cs[i] - cs[i-1]
          end
        end
        score = (cs[0] + diffs)*100 + bit.last.length
        if score < max
          score_match_pairs << [score, fn]
          score_match_pairs.sort!
          if score_match_pairs.length == 20
            max = score_match_pairs.last.first
          end
        end
  		end
		end
	end
  score_match_pairs.map {|a| a.last }
end

def make_regex(text)
  re_src = "(" + text.split(//).map{|l| Regexp.escape(l) }.join(").*?(") + ")"
  Regexp.new(re_src)
end

s = Time.now
result = find_files("t", ["/home/dan/projects/skweb/"])
puts "took #{Time.now - s}s"
result.each do |file|
  # puts file
  
end
  
