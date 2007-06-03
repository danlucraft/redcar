
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

new_command(:make_executable, :menu => false) do
  if lines.first =~ /^#!/
      FileUtils.chmod(buffers.current.filename, 777)
  end
end

new_command("Global Find/Replace", 
            :menu => :edit) do
  find, replace, case_on = dialog([["Find", :find, :text], 
                                   ["Replace", :replace, :text],
                                   ["Case Insensitive", :case_on, :boolean]]
  project.files.each do |file|
    file.open
    if case_on
      file.contents.gsub!(/#{find}/i, replace)
    else
      file.contents.gsub!(find, replace)
    end
    file.save
    file.close
  end
end

class Redcar::File
  def nice_name
    @filename.split("/").last
  end
end

class Redcar::File
  alias :perform_save, :old_perform_save
  def perform_save
    if @filename =~ /ftp:/
      use_remote_save(@filename, @contents)
    else
      old_perform_save
    end
  end
  
  alias :perform_load, :old_perform_load
  def perform_load
    if @filename =~ /ftp:/
      @contents = use_remote_load(@filename)
    else
      old_perform_load
    end
  end
end

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

new_command(:make_executable, :menu => false) do
  if lines.first =~ /^#!/
      FileUtils.chmod(buffers.current.filename, 777)
  end
end

new_command("Global Find/Replace", 
            :menu => :edit) do
  find, replace, case_on = dialog([["Find", :find, :text], 
                                   ["Replace", :replace, :text],
                                   ["Case Insensitive", :case_on, :boolean]]
  project.files.each do |file|
    file.open
    if case_on
      file.contents.gsub!(/#{find}/i, replace)
    else
      file.contents.gsub!(find, replace)
    end
    file.save
    file.close
  end
end

class Redcar::File
  def nice_name
    @filename.split("/").last
  end
end

class Redcar::File
  alias :perform_save, :old_perform_save
  def perform_save
    if @filename =~ /ftp:/
      use_remote_save(@filename, @contents)
    else
      old_perform_save
    end
  end
  
  alias :perform_load, :old_perform_load
  def perform_load
    if @filename =~ /ftp:/
      @contents = use_remote_load(@filename)
    else
      old_perform_load
    end
  end
end

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

new_command(:make_executable, :menu => false) do
  if lines.first =~ /^#!/
      FileUtils.chmod(buffers.current.filename, 777)
  end
end

new_command("Global Find/Replace", 
            :menu => :edit) do
  find, replace, case_on = dialog([["Find", :find, :text], 
                                   ["Replace", :replace, :text],
                                   ["Case Insensitive", :case_on, :boolean]]
  project.files.each do |file|
    file.open
    if case_on
      file.contents.gsub!(/#{find}/i, replace)
    else
      file.contents.gsub!(find, replace)
    end
    file.save
    file.close
  end
end

class Redcar::File
  def nice_name
    @filename.split("/").last
  end
end

class Redcar::File
  alias :perform_save, :old_perform_save
  def perform_save
    if @filename =~ /ftp:/
      use_remote_save(@filename, @contents)
    else
      old_perform_save
    end
  end
  
  alias :perform_load, :old_perform_load
  def perform_load
    if @filename =~ /ftp:/
      @contents = use_remote_load(@filename)
    else
      old_perform_load
    end
  end
end

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

new_command(:make_executable, :menu => false) do
  if lines.first =~ /^#!/
      FileUtils.chmod(buffers.current.filename, 777)
  end
end

new_command("Global Find/Replace", 
            :menu => :edit) do
  find, replace, case_on = dialog([["Find", :find, :text], 
                                   ["Replace", :replace, :text],
                                   ["Case Insensitive", :case_on, :boolean]]
  project.files.each do |file|
    file.open
    if case_on
      file.contents.gsub!(/#{find}/i, replace)
    else
      file.contents.gsub!(find, replace)
    end
    file.save
    file.close
  end
end

class Redcar::File
  def nice_name
    @filename.split("/").last
  end
end

class Redcar::File
  alias :perform_save, :old_perform_save
  def perform_save
    if @filename =~ /ftp:/
      use_remote_save(@filename, @contents)
    else
      old_perform_save
    end
  end
  
  alias :perform_load, :old_perform_load
  def perform_load
    if @filename =~ /ftp:/
      @contents = use_remote_load(@filename)
    else
      old_perform_load
    end
  end
end
