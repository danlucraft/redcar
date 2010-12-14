
class ProjectSearch
  class Hit
    attr_reader :file, :line_num
    
    def initialize(file, line_num, line, regex)
      @file, @line_num, @line, @regex = file, line_num, line, regex
    end
    
    def line(start_with=nil, end_with=nil)
      @line.gsub(@regex) { start_with.to_s + $& + end_with.to_s }
    end
  end
end