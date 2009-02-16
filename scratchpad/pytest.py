import sys, os, re, traceback
pattern = re.compile("and")
mate = "/home/dan/Projects/redcar/bin/redcar"
pb = os.popen(mate, "w")
for line in sys.stdin:
  if pattern.search(line):
    pb.write(line)
  else:
    sys.stdout.write(line)
pb.close()

# paul.darch@ntlworld.com
