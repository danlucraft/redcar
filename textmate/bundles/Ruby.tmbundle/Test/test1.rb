# Ruby syntax test file for stuff we've gotten wrong in the past or are currently getting wrong

#########
#basics

module samwi_78se
	
	class dubya < slime

	end
end

class gallo_way8 < kni9_ght

	def sl_9ay(beast)
		
	end
end


def hot?(cold)

end

def w00t!
	
	unless l33t
		sysbeep
	end
	
end

###########
# method names

# method names can be keywords and should not be highlighted if they appear as explicit method invocations
br = m.end(0) + b1
x, y = b2vxay(m.begin(0) + b1)
stream.next
self.class

############
# numbers

data += 0.chr
99.downto(0)

0.9		# number
0.A		# method invocation (0 -> A)
0xCAFEBABE022409ad802046	# hex
23402	# integer
4.232	# decimal


###########
# strings 

'hello #{42} wor\'knjkld'		# no interpolation or escapes except for slash-single-quote

# double quoted string (allows for interpolation):
"hello #{42} world"	  #->  "hello 42 world"
"hello #@ivar world"  #->  "hello 42 world"
"hello #@@cvar world" #->  "hello 42 world"
"hello #$gvar world"  #->  "hello 42 world"

'hello #@ivar world'
'hello #@@cvar world'
'hello #$gvar world'

# escapes
"hello #$gvar \"world"  #->  "hello 42 \"world"

# execute string (allows for interpolation):
%x{ls #{dir}}	 #-> ".\n..\nREADME\nmain.rb"
`ls #{dir}`   #-> ".\n..\nREADME\nmain.rb"

%Q{dude #{hey}}
%Q!dude#{hey}!
%W(dude#{hey})
%q!dude#{hey}!
%s{dude#{hey}}
%w{dude#{hey}}
%{woah#{hey}}
% woah#{hey} 

# mod operator should not be interpreted as a string operator
# (space as delimiter is legal Ruby: '% string ' => "string")
if (data.size % 2) == 1
line << ('%3s ' % str)


###########
# regexp

/matchmecaseinsensitive/i
/matchme/
/ matchme /
%r{matchme}

32/23	#division, not regexp

32 / 32 #division, not regexp

gsub!(/ +/, '')  #regexp, not division

###########
# symbols

:BIG  :aBC	:AbC9  :symb  :_asd	 :_9sd	:__=  :f00bar  :abc!
			:abc?  :abc=  :<<  :<  :>>	:>	:<=>  :<=  :>=	:%	:*	:**
			:+	:-	:&	:|	:~	:=~	 :==  :===	:`	:[]=  :[]  :/  :-@
			:+@	 :@aaa	:@@bbb

# else clause of ternary logic should not highlight as symbol
val?(a):p(b)
val?'a':'b'
M[1]?(a+b):p(c+d)

# but we must also account for ? in method names
thing.call?(:someone)
thing.call? :someone
thing.call? thing2, :someone

begin = {"(?=\\w)\\s*\\?:"}


############
#literal capable of interpolation:	 
%W(a b#{42}c) #-> ["a", "b42c"]
%W(ab c\nd \\\)ef)

%(#{42})  #->  "42"


############
# multiline comments

=begin
stuff here
... def must_not_highlight_keywords_in_comments end;
stuff here too
=end


############
#literal incapable of interpolation
%w(a b#{42}c) 					#-> ["a", "b#{42}c"]############
%w(ab c\nd \\\)ef)				# heredoc tests

append << not_heredoc

heredoc = <<END # C heredoc

void LoveMyCarpet( int forReal )
{
	forReal = 56;
}

END

assert_equal(2**i, 1<<i)


##########
# end marker

__END__

def nothing_here_should_be_highlighted!( at all )

end
