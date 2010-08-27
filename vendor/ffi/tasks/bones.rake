
if HAVE_BONES

namespace :bones do

  desc 'Show the PROJ open struct'
  task :debug do |t|
    atr = if t.application.top_level_tasks.length == 2
      t.application.top_level_tasks.pop
    end

    if atr then Bones::Debug.show_attr(PROJ, atr)
    else Bones::Debug.show PROJ end
  end

end  # namespace :bones

end  # HAVE_BONES

# EOF
