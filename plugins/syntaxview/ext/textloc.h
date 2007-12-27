
#ifndef TEXTLOC_H
#define TEXTLOC_H

#include <stdlib.h>

typedef struct TextLoc_ {
  int line;
  int offset;
} TextLoc;

#define TEXTLOC_EQUAL(t1, t2) (t1.line == t2.line && t1.offset == t2.offset)
#define TEXTLOC_GT(t1, t2) ((t1.line > t2.line) || (t1.line >= t2.line && t1.offset > t2.offset))
#define TEXTLOC_LT(t1, t2) (!TEXTLOC_EQUAL(t1, t2) && !TEXTLOC_GT(t1, t2))
#define TEXTLOC_GTE(t1, t2) (!TEXTLOC_LT(t1, t2))
#define TEXTLOC_LTE(t1, t2) (!TEXTLOC_GT(t1, t2))
#define TEXTLOC_VALID(t) (t.line != -1 && t.offset != -1)
#endif
