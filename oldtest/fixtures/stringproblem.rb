# This was my initial impression of what the user defined commands
# would look like.

new_command("Trim Whitespace", :menu => :edit, :location => :append) do 
  while lines.first =~ /^\s*$/
    lines.first.destroy
  end
  while lines.last =~ /^\s*$/
    lines.last.destroy
  end
  lines.each do |line|
    line.gsub!(/\s+$/, "")
  end
end

before_save "Trim Whitespace"
after_save  :make_executable
