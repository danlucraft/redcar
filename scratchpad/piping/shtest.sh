res=$(ruby -rui -e"print TextMate::UI.request_string(:title => 'Distill Text', :prompt => 'Enter a pattern:', :button1 => 'Filter', :button2 => 'Cancel').to_s")

[[ -z "$res" ]] && exit_discard
export pattern="$res"
echo $res
# This could be done with grep, but Python's RE is closer to oniguruma
"${TM_PYTHON:-python}" -c '
import sys, os, re, traceback
try:
  pattern = re.compile(os.environ["pattern"])
except re.error, e:
  sys.stderr.write("Invalid pattern: %s" % e)
  sys.exit(1)
#mate = "\"%s/bin/mate\" -a" % os.environ["TM_SUPPORT_PATH"]
mate = "/home/dan/projects/redcar/bin/redcar -d --log"
pb = os.popen(mate, "w")
for line in sys.stdin:
  if pattern.search(line):
    pb.write(line)
  else:
    sys.stdout.write(line)
pb.close()
' || exit_show_tool_tip

