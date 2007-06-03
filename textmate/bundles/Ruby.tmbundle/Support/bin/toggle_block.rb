#!/usr/bin/env ruby -w

# FIXME:  In a ruby code line like "lines.each { |line| puts "#{i += 1}. " + line }", the "switch between {} and do-end" command picks up the wrong braces.
# allan: JEG2: maybe we should just let a script do the extraction rather than the current regexp find in a macro
# allan: but with a script it’s fairly easy — we can even let the script take XML as input so that it can leverage TMs parser to find code blocks etc.

require "escape"

# Unicode code point 0xFFFC
CURSOR = [0xFFFC].pack("U").freeze

def toggle_block( block_text )
  result = block_text.dup
  
  case result.to_a.size
  when 1  # single line to multi-line transform
    # find the '}' relative to the cursor
    if c = result.index(CURSOR)
      i = result.index("}", c) or raise "'}' not found."
    else
      i = result.rindex("}") or raise "'}' not found."
    end
    # convert
    result[i, 1] = "\nend"
    
    # find '{' with proper nesting allowed
    i = result.rindex("{") or raise "'{' not found"
    while (nested = result.rindex("}")) and nested > i and i > 0
      if prev = result.rindex("{", i - 1)
        i = prev
      else
        break
      end
    end
    # convert
    if i > 0 and result[i - 1, 1][/\w/]
      result[i, 1] =  " do"
      i            += 1
    else
      result[i, 1] = "do"
    end
    
    # drop in the newline after the parameters, if present
    if params = result[(i + 2)..-1][/([ \t]*\|[^|]*\|)([ \t]*)/, 1]
      result[i + 2 + params.size, 0]           = "\n"
      result[i + 2 + params.size + 1, $2.size] = "" unless $2.empty?
    else
      result[i + 2, 0] = "\n"
      if result[(i + 3)..-1][/[ \t]*/]
        result[(i + 3), $&.size] = ""
      end
    end
    
    # properly indent the remaining lines
    indent = result[/\A[ \t]*/]
    lines  = result.to_a
    result = [ lines.first,
               lines[1..-2].map { |line| line[indent.size, 0] = "\t"; line },
               lines.last ].join
    
    # strip trailing line whitespace
    result.sub!(/(\S)[ \t]+\n/, "\\1\n")
  when 2..1.0/0.0  # multi-line to single line transform
    lines = result.to_a
    lines.each { |line| line.chomp! }
    
    # flop 'do' to '{'
    d       = lines.shift
    i       = d.index(/\bdo\b/) or raise "'do' not found."
    d[i, 2] = "{"
    d << "; " unless d[(i + 1)..-1] =~ /\A\s*?(?:\|[^|]*\|)?\s*\Z/
    d << " "  unless d =~ /\s+\Z/
    
    # flop 'end' to '}'
    (e = lines.pop).sub!(/\A\s*(\S*)\s*\bend\b\s*/, "\\1 }") \
      or raise "'end' not found."
    e = "; " + e unless e =~ /\A\s+/
    
    # rejoin lines, adding ';'s as needed
    lines.each { |line| line.strip! }
    result = [d, lines.join("; "), e].join
  else
    raise "No lines to convert."
  end
  
  result
rescue        # if anything goes wrong...
  block_text  # just send back the original text
end

if __FILE__ == $PROGRAM_NAME
  print e_sn(toggle_block(STDIN.read)).gsub(CURSOR, "$0")
end
