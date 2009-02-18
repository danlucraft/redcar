
import sys, os, re, traceback

pattern = re.compile("and")
<<<<<<< HEAD:scratchpad/piping/pytest.py
mate = "/home/dan/projects/redcar/bin/redcar -d --log"
=======

mate = "/home/dan/Projects/redcar/bin/redcar"
>>>>>>> More fiddling with process control:scratchpad/pytest.py
pb = os.popen(mate, "w")
for line in sys.stdin:
  if pattern.search(line):
    pb.write(line)
  else:
    sys.stdout.write(line)
pb.close()

# paul.darch@ntlworld.com
