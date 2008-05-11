
// ----- Scope object

#include "ruby.h"
#include "textloc.h"
#include <gtk/gtk.h>
#include <glib.h>

typedef struct ScopeData_ {
  GtkTextMark *start_mark;
  GtkTextMark *inner_start_mark;
  GtkTextMark *inner_end_mark;
  GtkTextMark *end_mark;
  GtkTextTag *tag;
  GtkTextTag *inner_tag;
  char* name;
  char* bg_color;
  int coloured;
  int numcolourings;
  int open;
  VALUE rb_scope;
} ScopeData;

typedef GNode Scope;

void mark_to_iter(GtkTextMark* mark, GtkTextIter* iter);
void scope_start_loc(Scope* scope, TextLoc* textloc);
void scope_inner_start_loc(Scope* scope, TextLoc* textloc);
void scope_end_loc(Scope* scope, TextLoc* textloc);
void scope_inner_end_loc(Scope* scope, TextLoc* textloc);
int scope_active_on_line(Scope* scope, int line);
int scope_overlaps(Scope* s1, Scope* s2);
int scope_add_child(Scope* parent, Scope* new_child, Scope* starting_child);
int scope_clear_after(Scope* s, TextLoc* loc);
int scope_clear_between(Scope* s, TextLoc* from, TextLoc* to);
int scope_clear_between_lines(Scope* s, int from, int to);
int scope_free_data(Scope* scope);
Scope* scope_at(Scope* s, TextLoc* loc);
int scope_get_priority(Scope* scope);
int delete_marks(GtkTextBuffer *buffer, Scope *scope);
char* scope_nearest_bg_color(Scope* scope);
