

typedef struct TextLoc_ {
  int line;
  int offset;
} TextLoc;

int textloc_equal(TextLoc* t1, TextLoc* t2);
int textloc_gt(TextLoc* t1, TextLoc* t2);
int textloc_lt(TextLoc* t1, TextLoc* t2);
int textloc_gte(TextLoc* t1, TextLoc* t2);
int textloc_lte(TextLoc* t1, TextLoc* t2);
int textloc_valid(TextLoc* t);
