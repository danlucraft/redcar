
#include "ruby.h"
#include <gtk/gtk.h>
#include <glib.h>
#include <string.h>
#include <oniguruma.h>

static VALUE rb_scope_print(VALUE self, VALUE indent);

void print_iter(GtkTextIter* iter) {
  printf("<%d,%d>",
	 gtk_text_iter_get_line(iter),
	 gtk_text_iter_get_line_offset(iter));
  return;
}

/* ------------- TextLoc */

typedef struct TextLoc_ {
  int line;
  int offset;
} TextLoc;

int textloc_init(TextLoc* t) {
  t->line = -1;
  t->offset = -1;
}

int textloc_equal(TextLoc* t1, TextLoc* t2) {
  return (t1->line == t2->line && t1->offset == t2->offset);
}

int textloc_gt(TextLoc* t1, TextLoc* t2) {
  return ((t1->line > t2->line) || (t1->line >= t2->line && t1->offset > t2->offset));
}

int textloc_lt(TextLoc* t1, TextLoc* t2) {
  return (!textloc_equal(t1, t2) && !textloc_gt(t1, t2));
}

int textloc_gte(TextLoc* t1, TextLoc* t2) {
  return (!textloc_lt(t1, t2));
}

int textloc_lte(TextLoc* t1, TextLoc* t2) {
  return (!textloc_gt(t1, t2));
}

int textloc_valid(TextLoc* t) {
  return (t->line != -1 && t->offset != -1);
}

static void rb_textloc_destroy(void* tl) {
  free(tl);
}

static VALUE rb_textloc_alloc(VALUE klass) {
  TextLoc *textloc = malloc(sizeof(TextLoc));
  textloc_init(textloc);
  VALUE obj;
  obj = Data_Wrap_Struct(klass, 0, rb_textloc_destroy, textloc);
  return obj;
}

static VALUE rb_textloc_init(VALUE self, VALUE line, VALUE offset) {
  TextLoc *textloc;
  Data_Get_Struct(self, TextLoc, textloc);
  textloc->line = FIX2INT(line);
  textloc->offset = FIX2INT(offset);
  return self;
}

static VALUE rb_textloc_line(VALUE self, VALUE rbt) {
  TextLoc *t;
  Data_Get_Struct(self, TextLoc, t);
  return INT2FIX(t->line);
}

static VALUE rb_textloc_offset(VALUE self, VALUE rbt) {
  TextLoc *t;
  Data_Get_Struct(self, TextLoc, t);
  return INT2FIX(t->offset);
}

static VALUE rb_textloc_equal(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  if (rbt == Qnil) {
    if (!textloc_valid(t1))
      return Qtrue;
    else
      return Qfalse;
  }
	
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_equal(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_lt(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_lt(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_gt(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_gt(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_gte(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_gte(t1, t2))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_textloc_lte(VALUE self, VALUE rbt) {
  TextLoc *t1, *t2;
  Data_Get_Struct(self, TextLoc, t1);
  Data_Get_Struct(rbt, TextLoc, t2);
  if (textloc_lte(t1, t2))
    return Qtrue;
  return Qfalse;
}

/* ----------------- end TextLoc */

// ----- Get a GTK object from a Ruby-Gnome object ----
typedef struct {
    VALUE self;
    GObject* gobj;
    void* cinfo;
    gboolean destroyed;
} my_gobj_holder;

GObject* get_gobject(VALUE rbgobj) {
  my_gobj_holder *gh;
  Data_Get_Struct(rbgobj, my_gobj_holder, gh);
  return gh->gobj;
}

// ----- Scope object

typedef struct ScopeData_ {
  GtkTextMark *start_mark;
  GtkTextMark *inner_start_mark;
  GtkTextMark *inner_end_mark;
  GtkTextMark *end_mark;
  VALUE rb_start_mark;
  VALUE rb_inner_start_mark;
  VALUE rb_inner_end_mark;
  VALUE rb_end_mark;
  char* name;
  VALUE rb_scope;
  int coloured;
  GtkTextTag *tag;
  GtkTextTag *inner_tag;
} ScopeData;

typedef GNode Scope;

void mark_to_textloc(GtkTextMark* mark, TextLoc* textloc) {
  GtkTextBuffer* buffer;
  GtkTextIter iter;
  buffer = gtk_text_mark_get_buffer(mark);
  gtk_text_buffer_get_iter_at_mark(buffer, &iter, mark);
  textloc->line   = (int) gtk_text_iter_get_line(&iter);
  textloc->offset = (int) gtk_text_iter_get_line_offset(&iter);
  return;
}

void mark_to_iter(GtkTextMark* mark, GtkTextIter* iter) {
  GtkTextBuffer* buffer;
  buffer = gtk_text_mark_get_buffer(mark);
  gtk_text_buffer_get_iter_at_mark(buffer, iter, mark);
  return;
}

void scope_start_loc(Scope* scope, TextLoc* textloc) {
  ScopeData *sd = scope->data;
  if (sd->start_mark == NULL) {
    printf("scope_start %s: missing mark\n", sd->name);
  }
  mark_to_textloc(sd->start_mark, textloc);
  return;
}

void scope_inner_start_loc(Scope* scope, TextLoc* textloc) {
  ScopeData *sd = scope->data;
  if (sd->inner_start_mark == NULL) {
    scope_start_loc(scope, textloc);
    return;
  }
  mark_to_textloc(sd->inner_start_mark, textloc);
  return;
}

void scope_end_loc(Scope* scope, TextLoc* textloc) {
  ScopeData *sd = scope->data;
  if (sd->end_mark == NULL) {
    printf("scope_end %s: missing mark\n", sd->name);
  }
  mark_to_textloc(sd->end_mark, textloc);
  return;
}

void scope_inner_end_loc(Scope* scope, TextLoc* textloc) {
  ScopeData *sd = scope->data;
  if (sd->inner_end_mark == NULL) {
    scope_end_loc(scope, textloc);
    return;
  }
  mark_to_textloc(sd->inner_end_mark, textloc);
  return;
}

int scope_active_on_line(Scope* scope, int line) {
  TextLoc start;
  TextLoc end;
  scope_start_loc(scope, &start);
  scope_end_loc(scope, &end);
  if (start.line <= line)
    if (end.line >= line)
      return 1;
  return 0;
}

int scope_overlaps(Scope* s1, Scope* s2) {
  GtkTextIter start1, start2;
  GtkTextIter end1, end2;
  ScopeData *sd1 = s1->data;
  ScopeData *sd2 = s2->data;

  // sd1     +---
  // sd2  +---
  mark_to_iter(sd1->start_mark, &start1);
  mark_to_iter(sd2->start_mark, &start2);
  if (gtk_text_iter_compare(&start1, &start2) >= 0) {
    mark_to_iter(sd2->end_mark, &end2);
    if (gtk_text_iter_compare(&start1, &end2) < 0)
      return 1;
    return 0;
  }

  // sd1 +----
  // sd2   +---
  mark_to_iter(sd1->end_mark, &end1);
  if (gtk_text_iter_compare(&end1, &start2) > 0)
    return 1;
  return 0;
}

int scope_add_child(Scope* parent, Scope* new_child) {
  Scope *child;
  TextLoc p_start, p_end;
  TextLoc nc_start, nc_end;
  TextLoc c_start, c_end;
  scope_start_loc(parent, &p_start);
  scope_end_loc(parent, &p_end);
  scope_start_loc(new_child, &nc_start);
  scope_end_loc(new_child, &nc_end);
  if (g_node_n_children(parent) == 0) {
    g_node_append(parent, new_child);
    return 1;
  }
  else {
    child = g_node_last_child(parent);
    scope_start_loc(child, &c_start);
    scope_end_loc(child, &c_end);
    if (textloc_gte(&nc_start, &c_end)) {
      g_node_append(parent, new_child);
      return 1;
    }
  }
  Scope *insert_after = NULL;
  int i;
  child = g_node_first_child(parent);
  while(child != NULL) {
    scope_start_loc(child, &c_start);
    scope_end_loc(child, &c_end);
    if (textloc_lte(&c_start, &nc_start))
      insert_after = child;
    child = g_node_next_sibling(child);
  }
  g_node_insert_after(parent, insert_after, new_child);
  return 1;
}

int scope_clear_after(Scope* s, TextLoc* loc) {
  Scope *c;
  TextLoc c_start, c_end;
  int i;
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    scope_start_loc(c, &c_start);
    if (textloc_gte(&c_start, loc)) {
      g_node_unlink(c);
      i -= 1;
    } else {
      scope_clear_after(c, loc);
    }
  }
  return 1;
}

int scope_clear_between(Scope* s, TextLoc* from, TextLoc* to) {
  Scope *c;
  TextLoc c_start, c_end;
  int i;
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    scope_start_loc(c, &c_start);
    scope_end_loc(c, &c_end);
    if ((textloc_gte(&c_start, from) && 
         textloc_lt(&c_start, to)) ||
        (textloc_gte(&c_end, from) &&
         textloc_lt(&c_end, to))) {
      g_node_unlink(c);
      i -= 1;
    } else {
      scope_clear_between(c, from, to);
    }
  }
  return 1;
}

int scope_clear_between_lines(Scope* s, int from, int to) {
  Scope *c;
  ScopeData *sd, *sdc;
  TextLoc c_start, c_end;

  int i;
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    scope_start_loc(c, &c_start);
    if (c_start.line >= from && c_start.line <= to) {
      g_node_unlink(c);
      i -= 1;
    } else {
      scope_clear_between_lines(c, from, to);
    }
  }
  return 1;
}

static VALUE rb_scope_cinit(VALUE self) {
  Scope *scope;
  Data_Get_Struct(self, Scope, scope);
  ScopeData *sd = scope->data;
  sd->name = NULL;
  sd->coloured = 0;
  sd->rb_scope = self;
  sd->tag = NULL;
  sd->inner_tag = NULL;
  sd->start_mark = NULL;
  sd->inner_start_mark = NULL;
  sd->inner_end_mark = NULL;
  sd->end_mark = NULL;
  sd->rb_start_mark = Qnil;
  sd->rb_inner_start_mark = Qnil;
  sd->rb_inner_end_mark = Qnil;
  sd->rb_end_mark = Qnil;
  return self;
}

static VALUE rb_scope_init(VALUE self, VALUE options) {
  Scope *scope;
  Data_Get_Struct(self, Scope, scope);
  ScopeData *sd = scope->data;
  rb_scope_cinit(self);
  rb_funcall(self, rb_intern("initialize2"), 1, options);
  return self;
}

int scope_free_data(Scope* scope) {
  //  free(((ScopeData *) scope->data)->name);
  // don't free the name because it's likely an RSTRING
  // FIXME: Scope's need buffers and we need to free marks when
  // we free the scope
  free(scope->data);
  return FALSE;
}

void rb_scope_destroy(Scope* scope) {
  scope_free_data(scope);
  //  g_node_destroy((gpointer) scope);
  return;
}

void rb_scope_mark(Scope* scope) {
  Scope *child;
  ScopeData *sd = scope->data;
  ScopeData *sdc = NULL;
  int i;
  for (i = 0; i < g_node_n_children(scope); i++) {
    child = g_node_nth_child(scope, i);
    sdc = child->data;
    rb_gc_mark(sdc->rb_scope);
  }
}

static VALUE rb_scope_alloc(VALUE klass) {
  Scope *scope;
  VALUE obj;
  ScopeData* scope_data = malloc(sizeof(ScopeData));
  scope = g_node_new((gpointer) scope_data);
  obj = Data_Wrap_Struct(klass, rb_scope_mark, rb_scope_destroy, scope);
  scope_data->rb_scope = obj;
  return obj;
}

static VALUE rb_scope_print(VALUE self, VALUE indent) {
  if (self == Qnil || indent == Qnil)
    printf("scope_print(nil or nil)");
  Scope *s, *child;
  int in = FIX2INT(indent);
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  char *name = "noname";
  if (sd->name)
    name = sd->name;
  int i;
  for (i = 0; i < in; i++)
    printf(" ");

  TextLoc start, end;
  scope_start_loc(s, &start);
  scope_end_loc(s, &end);
  printf("<scope %p %s (%d,%d)-(%d,%d)>\n",
	 s, name,
  	 start.line, start.offset, end.line,
  	 end.offset);
  for (i = 0; i < g_node_n_children(s); i++) {
    child = g_node_nth_child(s, i);
    sd = child->data;
    rb_scope_print(sd->rb_scope, INT2FIX(in+2));
  }
  return Qnil;
}

static VALUE rb_scope_get_start_line(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->start_mark;
  if (sd->start_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.line);
}

static VALUE rb_scope_get_start_line_offset(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->start_mark;
  if (sd->start_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.offset);
}

static VALUE rb_scope_get_inner_start_line(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->inner_start_mark;
  if (sd->inner_start_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.line);
}

static VALUE rb_scope_get_inner_start_line_offset(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->inner_start_mark;
  if (sd->inner_start_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.offset);
}

static VALUE rb_scope_get_inner_end_line(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->inner_end_mark;
  if (sd->inner_end_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.line);
}

static VALUE rb_scope_get_inner_end_line_offset(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->inner_end_mark;
  if (sd->inner_end_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.offset);
}

static VALUE rb_scope_get_end_line(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->end_mark;
  if (sd->end_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.line);
}

static VALUE rb_scope_get_end_line_offset(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  GtkTextMark* mark = sd->end_mark;
  if (sd->end_mark == NULL)
    return Qnil;
  TextLoc loc;
  mark_to_textloc(mark, &loc);
  return INT2FIX(loc.offset);
}

static VALUE rb_scope_set_start_mark(VALUE self, VALUE rb_buffer, 
                                     VALUE rb_offset, VALUE rb_left_grav) {
  if (self == Qnil)
    printf("rb_scope_set_start_mark(nil)");
  Scope *s;
  ScopeData *sd;
  GtkTextBuffer *buffer;
  GtkTextIter iter;
  GtkTextMark *mark;
  int left_grav = 1;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);
  gtk_text_buffer_get_iter_at_offset(buffer, &iter, NUM2INT(rb_offset));
  if (rb_left_grav == Qtrue || rb_left_grav == Qnil)
    left_grav = 1;
  else
    left_grav = 0;
  mark = gtk_text_buffer_create_mark(buffer, NULL, &iter, (gboolean) left_grav);
  //  sd->rb_start_mark = rb_mark;
  sd->start_mark = mark;
  return Qnil;
}

static VALUE rb_scope_set_inner_start_mark(VALUE self, VALUE rb_buffer, 
                                           VALUE rb_offset, VALUE rb_left_grav) {
  if (self == Qnil)
    printf("rb_scope_set_inner_start_mark(nil)");
  Scope *s;
  ScopeData *sd;
  GtkTextBuffer *buffer;
  GtkTextIter iter;
  GtkTextMark *mark;
  int left_grav;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);
  gtk_text_buffer_get_iter_at_offset(buffer, &iter, NUM2INT(rb_offset));
  if (rb_left_grav == Qtrue || rb_left_grav == Qnil)
    left_grav = 1;
  else
    left_grav = 0;
  mark = gtk_text_buffer_create_mark(buffer, NULL, &iter, left_grav);
  sd->inner_start_mark = mark;
  return Qnil;
}

static VALUE rb_scope_set_inner_end_mark(VALUE self, VALUE rb_buffer, 
                                         VALUE rb_offset, VALUE rb_left_grav) {
  if (self == Qnil)
    printf("rb_scope_set_inner_end_mark(nil)");
  Scope *s;
  ScopeData *sd;
  GtkTextBuffer *buffer;
  GtkTextIter iter;
  GtkTextMark *mark;
  int left_grav;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);
  if (sd->inner_end_mark && sd->coloured) {
    sd->coloured = 0;
    uncolour_scope(buffer, s, 0);
    gtk_text_buffer_delete_mark(buffer, sd->inner_end_mark);
  }
  gtk_text_buffer_get_iter_at_offset(buffer, &iter, NUM2INT(rb_offset));
  if (rb_left_grav == Qtrue || rb_left_grav == Qnil)
    left_grav = 1;
  else
    left_grav = 0;
  mark = gtk_text_buffer_create_mark(buffer, NULL, &iter, left_grav);
  sd->inner_end_mark = mark;
  return Qnil;
}

static VALUE rb_scope_set_end_mark(VALUE self, VALUE rb_buffer, 
                                   VALUE rb_offset, VALUE rb_left_grav) {
  if (self == Qnil)
    printf("rb_scope_set_end_mark(nil)");
  Scope *s;
  ScopeData *sd;
  GtkTextBuffer *buffer;
  GtkTextIter iter;
  GtkTextMark *mark;
  int left_grav;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);
  if (sd->end_mark && sd->coloured) {
    sd->coloured = 0;
    uncolour_scope(buffer, s, 0);
    gtk_text_buffer_delete_mark(buffer, sd->end_mark);
  }
  gtk_text_buffer_get_iter_at_offset(buffer, &iter, NUM2INT(rb_offset));
  if (rb_left_grav == Qtrue || rb_left_grav == Qnil)
    left_grav = 1;
  else
    left_grav = 0;
  mark = gtk_text_buffer_create_mark(buffer, NULL, &iter, left_grav);
  sd->end_mark = mark;
  return Qnil;
}

static VALUE rb_scope_set_name(VALUE self, VALUE name) {
  if (self == Qnil)
    printf("rb_scope_set_name(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (name == Qnil)
    sd->name = NULL;
  else
    sd->name = RSTRING_PTR(name); // what if the string gets garbage collected?
                                  // This shouldn't happen in Redcar
                                  // because the grammars are always in memory.
  return Qnil;
}

static VALUE rb_scope_get_name(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_get_name(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (sd->name)
    return rb_str_new2(sd->name);
  else
    return Qnil;
}

// Boolean scope methods

static VALUE rb_scope_active_on_line(VALUE self, VALUE line_num) {
  if (self == Qnil || line_num == Qnil)
    printf("rb_scope_active_on_line(nil, or nil)");
  int num = FIX2INT(line_num);
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  if (scope_active_on_line(s, num))
      return Qtrue;
  return Qfalse;
}

static VALUE rb_scope_overlaps(VALUE self, VALUE other) {
  if (self == Qnil || other == Qnil)
    printf("rb_scope_overlaps(nil, or nil)");
  Scope *s1, *s2;
  ScopeData *sd1, *sd2;
  Data_Get_Struct(self, Scope, s1);
  Data_Get_Struct(other, Scope, s2);
  if (scope_overlaps(s1, s2))
    return Qtrue;
  return Qfalse;
}

// Scope children methods

Scope* scope_at(Scope* s, TextLoc* loc) {
  Scope *scope, *child;
  int i;

  TextLoc s_start, s_end;
  TextLoc c_start, c_end;
  scope_start_loc(s, &s_start);
  scope_end_loc(s, &s_end);
  if (textloc_lte(&s_start, loc) || G_NODE_IS_ROOT(s)) {
    if (textloc_gt(&s_end, loc)) {
      if (g_node_n_children(s) == 0) {	
        return s;
      }
      child = g_node_last_child(s);
      scope_start_loc(child, &c_start);
      scope_end_loc(child, &c_end);
      if (textloc_lt(&c_end, loc)) {	
        return s;
      }
      for (i = 0; i < g_node_n_children(s); i++) {
        child = g_node_nth_child(s, i);
        scope = scope_at(child, loc);
        if (scope != NULL) {	
          return scope;
	}
      }	
      return s;
    }
    else {	
      return NULL;
    }
  }
  else {	
    return NULL;
  }
}

static VALUE rb_scope_at(VALUE self, VALUE rb_loc) {
  Scope *s, *scope;
  ScopeData *sd;
  TextLoc *loc;
  Data_Get_Struct(self, Scope, s);
  Data_Get_Struct(rb_loc, TextLoc, loc);
  scope = scope_at(s, loc);
  if (scope == NULL)
    return Qnil;
  else {
    sd = scope->data;
    return sd->rb_scope;
  }
}

static VALUE rb_scope_first_child_after(VALUE self, VALUE rb_loc, VALUE rb_starting_child) {
  Scope *s, *child;
  Scope *starting_child = NULL;
  ScopeData *sd;
  TextLoc *loc;
  TextLoc c_start;
  Data_Get_Struct(self, Scope, s);
  Data_Get_Struct(rb_loc, TextLoc, loc);
  if (rb_starting_child != Qnil)
    Data_Get_Struct(rb_starting_child, Scope, starting_child);
  if (g_node_n_children(s) == 0)
    return Qnil;
  if (starting_child && starting_child->parent == s) {
    //    printf(":");
    child = starting_child;
  }
  else {
    //    printf(".");
    child = g_node_first_child(s);
  }
  while (child != NULL) {
    sd = child->data;
    scope_start_loc(child, &c_start);
    if (textloc_gte(&c_start, loc))
      return sd->rb_scope;
    child = g_node_next_sibling(child);
  }
  return Qnil;
}

static VALUE rb_scope_add_child(VALUE self, VALUE c_scope) {
  if (self == Qnil || c_scope == Qnil)
    printf("rb_scope_add_child(nil, or nil)");
  Scope *sp, *sc, *lc;
  ScopeData *sdp, *sdc, *lcd, *current_data;
  Data_Get_Struct(self, Scope, sp);
  Data_Get_Struct(c_scope, Scope, sc);

  if (scope_add_child(sp, sc))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_scope_clear_after(VALUE self, VALUE rb_loc) {
  if (self == Qnil || rb_loc == Qnil)
    printf("rb_scope_clear_after(nil, or nil)");
  TextLoc* loc;
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  Data_Get_Struct(rb_loc, TextLoc, loc);
  if (scope_clear_after(s, loc))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_scope_n_children(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_n_children(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  return INT2FIX(g_node_n_children(s));
}

static VALUE rb_scope_clear_between(VALUE self, VALUE rb_from, VALUE rb_to) {
  if (self == Qnil || rb_from == Qnil || rb_to == Qnil)
    printf("rb_scope_clear_between(nil, or nil, or nil)");
  TextLoc *from, *to;
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  Data_Get_Struct(rb_from, TextLoc, from);
  Data_Get_Struct(rb_to, TextLoc, to);
  if (scope_clear_between(s, from, to))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_scope_clear_between_lines(VALUE self, VALUE rb_from, VALUE rb_to) {
  if (self == Qnil || rb_from == Qnil || rb_to == Qnil)
    printf("rb_scope_clear_between_lines(nil, or nil, or nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  if (scope_clear_between_lines(s, FIX2INT(rb_from), FIX2INT(rb_to)))
    return Qtrue;
  return Qfalse;
}

static VALUE rb_scope_detach(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_detach(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  if (s->parent)
    g_node_unlink(s);
  return Qtrue;
}

static VALUE rb_scope_delete_any_on_line_not_in(VALUE self, VALUE line_num, 
                                                VALUE scopes, VALUE rb_starting_child) {
  if (self == Qnil || line_num == Qnil || scopes == Qnil)
    printf("rb_scope_delete_any_on_line_not_in(nil, or nil, or nil)");
  Scope *s, *c, *cn, *s1;
  ScopeData *sdc;
  Scope *starting_child = NULL;
  if (rb_starting_child != Qnil)
    Data_Get_Struct(rb_starting_child, Scope, starting_child);
  Data_Get_Struct(self, Scope, s);
  int num = FIX2INT(line_num);
  int i, j, remove;
  VALUE rs1;
  TextLoc start;
  if (starting_child && starting_child->parent == s) {
    c = starting_child;
  }
  else {
    c = g_node_first_child(s);
  }
  VALUE rb_removed = rb_ary_new();
  while (c != NULL) {
    sdc = c->data;
    cn = g_node_next_sibling(c);
    scope_start_loc(c, &start);
    if (start.line > num)
      return rb_removed;
    if (start.line == num) {
      remove = TRUE;
      for (j = 0; j < RARRAY(scopes)->len; j++) {
        rs1 = rb_ary_entry(scopes, (long) j);
        Data_Get_Struct(rs1, Scope, s1);
        if (c == s1)
          remove = FALSE;
      }
      if (remove) {
        rb_ary_push(rb_removed, sdc->rb_scope);
        g_node_unlink(c);
        i -= 1;
      }
    }
    c = cn;
  }
  return rb_removed;
}

static VALUE rb_scope_clear_not_on_line(VALUE self, VALUE rb_num) {
  if (self == Qnil || rb_num == Qnil)
    printf("rb_scope_clear_not_on_line(nil, or nil)");
  Scope *s, *c;
  ScopeData *sd, *sdc;
  Data_Get_Struct(self, Scope, s);
  int i;
  int num = FIX2INT(rb_num);
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    sdc = c->data;
    if (rb_scope_active_on_line(sdc->rb_scope, rb_num) == Qfalse) {
      g_node_unlink(c);
      i -= 1;
    }
  }
}

static VALUE rb_scope_hierarchy_names(VALUE self, VALUE rb_inner) {
  if (self == Qnil)
    printf("rb_scope_hierarchy_names(nil)");
  Scope *scope, *parent;
  ScopeData *scope_data, *parent_data;
  VALUE names;
  VALUE next_inner;
  TextLoc parent_open_end, parent_close_start,
    start, end;
  Data_Get_Struct(self, Scope, scope);
  scope_data = scope->data;
  if (!G_NODE_IS_ROOT(scope)) {
    parent = scope->parent;
    parent_data = parent->data;
    scope_start_loc(scope, &start);
    scope_end_loc(scope, &end);
    scope_inner_start_loc(parent, &parent_open_end);
    scope_inner_end_loc(parent, &parent_close_start);
    if (textloc_gte(&start, &parent_open_end) &&
        (textloc_lte(&end, &parent_close_start)))
      next_inner = Qtrue;
    else
      next_inner = Qfalse;
    names = rb_scope_hierarchy_names(parent_data->rb_scope, next_inner);
  }
  else {
    names = rb_ary_new();
  } 
  if (scope_data->name)
    rb_ary_push(names, rb_str_new2(scope_data->name));
  VALUE rb_pattern, rb_pattern_content_name;
  rb_pattern = rb_funcall(scope_data->rb_scope,
                          rb_intern("pattern"),
                          0);
  if (rb_inner == Qtrue) {
    if (rb_pattern != Qnil) {
      rb_pattern_content_name = rb_funcall(rb_pattern,
                                           rb_intern("content_name"),
                                           0);
      if (rb_pattern_content_name != Qnil) {
        rb_ary_push(names, rb_pattern_content_name);
      }
    }
  }
  return names;
}

/* int scope_shift_chars(Scope* scope, int line, int amount, int offset) { */
/*   ScopeData *sd; */
/*   sd = scope->data; */
/*   if (sd->start.line == line) { */
/*     if (sd->start.offset > offset) { */
/*       sd->start.offset += amount; */
/*       sd->modified = 1; */
/*     } */
/*     if (textloc_valid(&sd->open_end) && sd->open_end.offset > offset) { */
/*       sd->open_end.offset += amount; */
/*       sd->modified = 1; */
/*     } */
/*   } */
/*   if (textloc_valid(&sd->end) && sd->end.line == line) { */
/*     if (sd->end.offset > offset) { */
/*       sd->end.offset += amount; */
/*       sd->modified = 1; */
/*       if (textloc_valid(&sd->close_start)) */
/*         sd->close_start.offset += amount; */
/*     } */
/*   } */

/*   Scope *child; */
/*   Scope *child2; */
/*   ScopeData *child_data; */
/*   child = g_node_first_child(scope); */
/*   while (child != NULL) { */
/*     scope_shift_chars(child, line, amount, offset); */
/*     child2 = g_node_next_sibling(child); */
/*     // if the chars have been shifted such that a child has  */
/*     // a length of zero or less, remove that child. */
/*     child_data = child->data; */
/*     if (textloc_valid(&child_data->end) && textloc_gte(&child_data->start, &child_data->end)) */
/*       g_node_unlink(child); */
/*     child = child2; */
/*   } */
/*   return 1; */
/* } */

/* static VALUE rb_scope_shift_chars(VALUE self, VALUE rb_line,  */
/* 				  VALUE rb_amount, VALUE rb_offset) { */
/*   int line = FIX2INT(rb_line); */
/*   int amount = FIX2INT(rb_amount); */
/*   int offset = FIX2INT(rb_offset); */
/*   Scope *s; */
/*   Data_Get_Struct(self, Scope, s); */
/*   scope_shift_chars(s, line, amount, offset); */
/*   return Qtrue; */
/* } */

/* int scope_remove_children_that_overlap(Scope* scope, Scope* other) { */
/*   ScopeData *od = other->data; */
/*   Scope *child; */
/*   ScopeData *child_data; */
/*   child = g_node_first_child(scope); */
/*   while (child != NULL) { */
/*     child_data = child->data; */
/*     if (scope_overlaps(child, other) && child != other) */
/*       g_node_unlink(child); */
/*     child = g_node_next_sibling(child); */
/*   } */
/*   return 1; */
/* } */

static VALUE rb_scope_remove_children_that_overlap(VALUE self, VALUE rb_other, VALUE rb_starting_child) {
  Scope *scope, *other;
  Scope *starting_child = NULL;
  Data_Get_Struct(self, Scope, scope);
  Data_Get_Struct(rb_other, Scope, other);
  if (rb_starting_child != Qnil)
    Data_Get_Struct(rb_starting_child, Scope, starting_child);
  //  scope_remove_children_that_overlap(scope, other);
  ScopeData *od = other->data;
  Scope *child;
  ScopeData *child_data;
  if (starting_child && starting_child->parent == scope)
    child = starting_child;
  else
    child = g_node_first_child(scope);
  VALUE rb_removed = rb_ary_new();
  while (child != NULL) {
    child_data = child->data;
    if (scope_overlaps(child, other) && child != other) {
      rb_ary_push(rb_removed, child_data->rb_scope);
      g_node_unlink(child);
    }
    child = g_node_next_sibling(child);
  }
  return rb_removed;
}

static VALUE rb_scope_delete_child(VALUE self, VALUE rb_scope) {
  if (self == Qnil || rb_scope == Qnil)
    printf("rb_scope_delete_child(nil, or nil)");
  Scope *parent, *child;
  Data_Get_Struct(self, Scope, parent);
  Data_Get_Struct(rb_scope, Scope, child);
  if (child->parent == parent)
    g_node_unlink(child);
  return Qtrue;
}

static VALUE rb_scope_get_children(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_get_children(nil)");
  Scope *scope, *child;
  ScopeData *sd, *cd;
  Data_Get_Struct(self, Scope, scope);
  int i;
  VALUE ary = rb_ary_new2(g_node_n_children(scope));
  for (i = 0; i < g_node_n_children(scope); i++) {
    child = g_node_nth_child(scope, i);
    cd = child->data;
    rb_ary_store(ary, i, cd->rb_scope);
  }
  return ary;
}

static VALUE rb_scope_get_parent(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_get_parent(nil)");
  Scope *scope, *parent;
  ScopeData *sd, *pd;
  Data_Get_Struct(self, Scope, scope);
  parent = scope->parent;
  if (parent == scope)
    printf("!!parent == self  ");
  if (parent) {
    pd = parent->data;
    return pd->rb_scope;
  }
  return Qnil;
}

// -------- Colouring stuff

int minify(int offset) {
  return (offset < 200 ? offset : 200);
}

#define xtod(c) ((c>='0' && c<='9') ? c-'0' : ((c>='A' && c<='F') ? c-'A'+10 : ((c>='a' && c<='f') ? c-'a'+10 : 0)))

/*     def self.merge_colour(str_colour1, str_colour2) */
/*       return nil unless str_colour1 */
/*       if str_colour2.length == 7  */
/*         str_colour2 */
/*       elsif str_colour2.length == 9 */
/*         #FIXME: what are the extra two hex values for?  */
/*         #(possibly they are an opacity) */
/*         #12345678 */
/*         #'#'+str_colour[3..-1] */
/*         pre_r   = str_colour1[1..2].hex */
/*         pre_g   = str_colour1[3..4].hex */
/*         pre_b   = str_colour1[5..6].hex */
/*         post_r   = str_colour2[1..2].hex */
/*         post_g   = str_colour2[3..4].hex */
/*         post_b   = str_colour2[5..6].hex */
/*         opacity  = str_colour2[7..8].hex.to_f */
/*         new_r   = (pre_r*opacity + post_r*(255-opacity))/255 */
/*         new_g = (pre_g*opacity + post_g*(255-opacity))/255 */
/*         new_b  = (pre_b*opacity + post_b*(255-opacity))/255 */
/*         '#'+("%02x"%new_r)+("%02x"%new_r)+("%02x"%new_b) */
/*       end */

/* void clean_colour(char* in_bg, char* parent_bg, char* out_bg) { */
/*   int r, g, b, t; */
/*   printf("clean_colour: in %s\n", in_bg); */
/*   printf("clean_colour: pa %s\n", parent_bg); */
/*   if (strlen(in_bg) == 7) */
/*     strcpy(out_bg, in_bg); */
/*   else { */
/*     in_bg[7] = '\0'; */
/*     strcpy(out_bg, in_bg); */
/*   } */
/* /\*     r = xtod(in[1])*16+xtod(in[2]); *\/ */
/* /\*     g = xtod(in[3])*16+xtod(in[4]); *\/ */
/* /\*     b = xtod(in[5])*16+xtod(in[6]); *\/ */
/* /\*     t = xtod(in[7])*16+xtod(in[8]); *\/ */
/* } */

void set_tag_properties(Scope* scope, GtkTextTag* tag, VALUE rbh_tm_settings) {
  ScopeData* sd = scope->data;
  VALUE rb_fg, rb_bg, rb_style, rb_parent_bg;
  char fg[10], bg[10];
  VALUE rb_cTheme = rb_eval_string("Redcar::EditView::Theme");
  rb_fg = rb_hash_aref(rbh_tm_settings, rb_str_new2("foreground"));
  if (rb_fg != Qnil) {
/*     clean_colour(RSTRING_PTR(rb_fg), NULL, fg); */
    g_object_set(G_OBJECT(tag), "foreground", RSTRING_PTR(rb_fg), NULL);
  }

  rb_bg = rb_hash_aref(rbh_tm_settings, rb_str_new2("background"));
  if (rb_bg != Qnil) {
    rb_parent_bg = rb_funcall(sd->rb_scope, rb_intern("nearest_bg_color"), 0);
/*     clean_colour(RSTRING_PTR(rb_bg), RSTRING_PTR(rb_parent_bg), bg); */
    rb_bg = rb_funcall(rb_cTheme, rb_intern("merge_colour"), 2, rb_parent_bg, rb_bg);
    g_object_set(G_OBJECT(tag), "background", RSTRING_PTR(rb_bg), NULL);
    rb_funcall(sd->rb_scope, rb_intern("bg_color="), 1, rb_bg);
  }

  rb_style = rb_hash_aref(rbh_tm_settings, rb_str_new2("fontStyle"));

  if (strstr(RSTRING_PTR(rb_style), "italic"))
    g_object_set(G_OBJECT(tag), "style", PANGO_STYLE_ITALIC, NULL);
  else
    g_object_set(G_OBJECT(tag), "style", PANGO_STYLE_NORMAL, NULL);
    
  if (strstr(RSTRING_PTR(rb_style), "underline"))
    g_object_set(G_OBJECT(tag), "underline", PANGO_UNDERLINE_SINGLE, NULL);
  else
    g_object_set(G_OBJECT(tag), "underline", PANGO_UNDERLINE_NONE, NULL);
    
/*   if (strstr(RSTRING_PTR(rb_style), "bold")) */
/*     g_object_set(G_OBJECT(tag), "weight", PANGO_WEIGHT_BOLD, NULL); */
    
  return;
}

void colour_scope(GtkTextBuffer* buffer, Scope* scope, VALUE theme, int inner) {
  ScopeData* sd = scope->data;
  GtkTextIter start_iter, end_iter;
  GtkTextIter buff_start_iter, buff_end_iter;
  VALUE rba_settings, rbh_setting, rb_settings, rb_settings_scope;
  VALUE rbh_tag_settings, rbh, rba_tag_settings, rba;
  VALUE rb_scope_id;
  char tag_name[256] = "nil";
  int priority = FIX2INT(rb_funcall(sd->rb_scope, rb_intern("priority"), 0));
  GtkTextTag* tag = NULL;
  GtkTextTagTable* tag_table;
  int i;
  char *get_tag_name;

  sd->coloured = 1;

  if (inner) {
    gtk_text_buffer_get_iter_at_mark(buffer, &start_iter, sd->inner_start_mark);
    gtk_text_buffer_get_iter_at_mark(buffer, &end_iter, sd->inner_end_mark);
    if (sd->inner_tag != NULL) {
      tag = sd->inner_tag;
/*       gtk_text_buffer_get_start_iter(buffer, &buff_start_iter); */
/*       gtk_text_buffer_get_end_iter(buffer, &buff_end_iter); */
/*       gtk_text_buffer_remove_tag(buffer, sd->inner_tag, */
/* 				 &buff_start_iter, &buff_end_iter); */
    }
  }
  else {
    gtk_text_buffer_get_iter_at_mark(buffer, &start_iter, sd->start_mark);
    gtk_text_buffer_get_iter_at_mark(buffer, &end_iter, sd->end_mark);
    if (sd->tag != NULL) {
      tag = sd->tag;
/*       gtk_text_buffer_get_start_iter(buffer, &buff_start_iter); */
/*       gtk_text_buffer_get_end_iter(buffer, &buff_end_iter); */
/*       gtk_text_buffer_remove_tag(buffer, sd->tag, */
/* 				 &buff_start_iter, &buff_end_iter); */
    }
  }
  
  if (tag == NULL) {
    rbh = rb_funcall(theme, rb_intern("global_settings"), 0);
    
    // set name
    rba_settings = rb_funcall(theme, rb_intern("settings_for_scope"), 2, sd->rb_scope, (inner ? Qtrue : Qnil));
    if (RARRAY(rba_settings)->len == 0) {
      snprintf(tag_name, 250, "EditView(%d):default", priority-1);
    }
    else {
      rbh_setting = rb_ary_entry(rba_settings, 0);
      rb_settings = rb_hash_aref(rbh_setting, rb_str_new2("settings"));
      rb_settings_scope = rb_hash_aref(rbh_setting, rb_str_new2("scope"));
      rb_scope_id = rb_funcall(sd->rb_scope, rb_intern("scope_id"), 0);
      if (rb_settings_scope != Qnil) {
        snprintf(tag_name, 250, "EditView(%d):%s ", 
                 priority-1, RSTRING_PTR(rb_settings_scope));
      }
      rbh_tag_settings = rb_funcall(theme, rb_intern("textmate_settings_to_pango_options"), 1, rb_settings);
    }
    
    // lookup or create tag
    tag_table = gtk_text_buffer_get_tag_table(buffer);
    
    tag = gtk_text_tag_table_lookup(tag_table, tag_name);
    if (tag == NULL) {
      tag = gtk_text_buffer_create_tag(buffer, tag_name, NULL);
    }
/*     printf("%s\n", tag_name); */
    if (RARRAY(rba_settings)->len > 0)
      set_tag_properties(scope, tag, rb_settings);

    if (inner)
      sd->inner_tag = tag;
    else
      sd->tag = tag;
  }

/*   // some logging stuff */
/*   printf("[Colour]   %s:%d  ", sd->name, priority-1); */
/*   print_iter(&start_iter); */
/*   printf("-"); */
/*   print_iter(&end_iter); */
/*   puts(""); */

  gtk_text_buffer_apply_tag(buffer, tag, &start_iter, &end_iter);
  return;
}

static VALUE rb_colour_line_with_scopes(VALUE self, VALUE rb_buffer, 
                                        VALUE theme, VALUE scopes) {
  GtkTextBuffer* buffer;
  GtkTextIter start_iter, end_iter;

  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);

  // colour each scope
  int i;
  VALUE rb_current, pattern, content_name;
  Scope* current;
  ScopeData* current_data;
  TextLoc start, end;
  for (i = 0; i < RARRAY(scopes)->len; i++) {
    rb_current = rb_ary_entry(scopes, i);
    Data_Get_Struct(rb_current, Scope, current);
    current_data = current->data;
    scope_start_loc(current, &start);
    scope_end_loc(current, &end);
    if (textloc_equal(&start, &end))
      continue;
    pattern = rb_iv_get(rb_current, "@pattern");
    content_name = Qnil;
    if (pattern != Qnil)
      content_name = rb_iv_get(pattern, "@content_name");
    if (current_data->name == NULL && pattern != Qnil && 
        content_name == Qnil)
      continue;
/*     if (current_data->coloured) */
/*       continue; */
    colour_scope(buffer, current, theme, 0);
    if (content_name != Qnil) {
      colour_scope(buffer, current, theme, 1);
    }
  }
  //  puts("");
  return Qnil;
}

int uncolour_scope(GtkTextBuffer *buffer, Scope *scope, int uncolour_children) {
  ScopeData* sd = scope->data;
  GtkTextIter start_iter, end_iter;
  
/*   printf("[Uncolour] %s  ", sd->name); */
  if (sd->inner_tag) {
    gtk_text_buffer_get_iter_at_mark(buffer, &start_iter, sd->inner_start_mark);
    gtk_text_buffer_get_iter_at_mark(buffer, &end_iter, sd->inner_end_mark);
    gtk_text_buffer_remove_tag(buffer, sd->inner_tag, &start_iter, &end_iter);
  }
  if (sd->tag) {
    gtk_text_buffer_get_iter_at_mark(buffer, &start_iter, sd->start_mark);
    gtk_text_buffer_get_iter_at_mark(buffer, &end_iter, sd->end_mark);
    gtk_text_buffer_remove_tag(buffer, sd->tag, &start_iter, &end_iter);
  }
/*   if (sd->tag || sd->inner_tag) { */
/*     printf(":"); */
/*     print_iter(&start_iter); */
/*     printf("-"); */
/*     print_iter(&end_iter); */
/*     puts(""); */
/*   } */
  if (uncolour_children) {
    Scope *child;
    child = g_node_first_child(scope);
    while(child != NULL) {
      uncolour_scope(buffer, child, 1);
      child = g_node_next_sibling(child);
    }
  }
  return 0;
}

static VALUE rb_uncolour_scopes(VALUE self, VALUE rb_colourer, VALUE scopes) {
/*   printf("%d in line.\n", RARRAY(scopes)->len); */
  VALUE rb_buffer;
  GtkTextBuffer* buffer;

  // remove all tags from line
  rb_buffer = rb_funcall(rb_iv_get(rb_colourer, "@sourceview"), rb_intern("buffer"), 0);
  
  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);

  // un colour each scope and children
  int i;
  VALUE rb_current;
  Scope* current;
  ScopeData* current_data;
  for (i = 0; i < RARRAY(scopes)->len; i++) {
    rb_current = rb_ary_entry(scopes, i);
    Data_Get_Struct(rb_current, Scope, current);
    uncolour_scope(buffer, current, 1);
  }
  return Qnil;
}

/// LineParser

typedef struct LineParser_ {
  int    line_length;
  int    line_num;
  int    pos;
  int    has_scope_marker;
  int    sm_from;
  VALUE  sm_pattern;
  VALUE  sm_matchdata;
  Scope* current_scope;
  int    sm_hint;
  Scope* starting_child;
} LineParser;

void rb_line_parser_mark(LineParser* lp) {
  return;
}

void rb_line_parser_destroy(LineParser* lp) {
  return;
}

static VALUE rb_line_parser_alloc(VALUE klass) {
  LineParser *lp = malloc(sizeof(LineParser));
  VALUE obj;
  obj = Data_Wrap_Struct(klass, rb_line_parser_mark, rb_line_parser_destroy, lp);
  return obj;
}

static VALUE rb_line_parser_init(VALUE self, VALUE parser,
                                 VALUE line_num, VALUE line, 
                                 VALUE opening_scope,
                                 VALUE last_child) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  lp->line_length = RSTRING_LEN(line);
  lp->line_num    = FIX2INT(line_num);
  lp->pos         = 0;
  lp->has_scope_marker = 0;
  lp->current_scope = NULL;
  lp->starting_child = NULL;
  rb_funcall(self, rb_intern("initialize2"), 4, 
             parser, line, opening_scope, last_child);
  return self;
}

static VALUE rb_line_parser_line_length(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  return INT2FIX(lp->line_length);
}

static VALUE rb_line_parser_line_num(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  return INT2FIX(lp->line_num);
}

static VALUE rb_line_parser_get_pos(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  return INT2FIX(lp->pos);
}

static VALUE rb_line_parser_set_pos(VALUE self, VALUE newpos) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  lp->pos = FIX2INT(newpos);
  return newpos;
}

static VALUE rb_line_parser_get_current_scope(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  Scope *s;
  ScopeData *sd;
  s = lp->current_scope;
  sd = s->data;
  return sd->rb_scope;
}

static VALUE rb_line_parser_set_current_scope(VALUE self, VALUE rb_scope) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  Scope *s;
  Data_Get_Struct(rb_scope, Scope, s);
  lp->current_scope = s;
  return Qtrue;
}

static VALUE rb_line_parser_get_starting_child(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  Scope *s;
  ScopeData *sd;
  if (lp->starting_child == NULL)
    return Qnil;
  s = lp->starting_child;
  sd = s->data;
  return sd->rb_scope;
}

static VALUE rb_line_parser_set_starting_child(VALUE self, VALUE rb_scope) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  if (rb_scope == Qnil) {
    lp->starting_child = NULL;
    return;
  }
  Scope *s;
  Data_Get_Struct(rb_scope, Scope, s);
  lp->starting_child = s;
  return Qtrue;
}

static VALUE rb_line_parser_reset_scope_marker(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  lp->has_scope_marker = 0;
  return Qnil;
}

static VALUE rb_line_parser_any_scope_markers(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  if (lp->has_scope_marker)
    return Qtrue;
  return Qfalse;
}

static VALUE rb_line_parser_get_scope_marker(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  VALUE rb_scope_marker;
  if (lp->has_scope_marker) {
    rb_scope_marker = rb_hash_new();
    rb_hash_aset(rb_scope_marker, ID2SYM(rb_intern("from")), INT2FIX(lp->sm_from));
    //    rb_hash_aset(rb_scope_marker, rb_intern("to"), INT2FIX(lp->sm_to));
    rb_hash_aset(rb_scope_marker, ID2SYM(rb_intern("md")), lp->sm_matchdata);
    rb_hash_aset(rb_scope_marker, ID2SYM(rb_intern("pattern")), lp->sm_pattern);
    return rb_scope_marker;
  }
  return Qnil;
}

int line_parser_update_scope_marker(LineParser *lp,
                                    int new_from, VALUE new_pattern, VALUE new_md) {
  int new_hint;
  if (rb_funcall(new_pattern, rb_intern("=="), 1, ID2SYM(rb_intern("close_scope"))) == Qtrue)
    new_hint = 0;
  else
    new_hint = FIX2INT(rb_funcall(new_pattern, rb_intern("hint"), 0));
  if (!lp->has_scope_marker) {
    lp->has_scope_marker = 1;
    lp->sm_from = new_from;
    lp->sm_pattern = new_pattern;
    lp->sm_matchdata = new_md;
    lp->sm_hint = new_hint;
  }
  else {
    if (new_from < lp->sm_from) {
      lp->has_scope_marker = 1;
      lp->sm_from = new_from;
      lp->sm_pattern = new_pattern;
      lp->sm_matchdata = new_md;
      lp->sm_hint = new_hint;
    }
    else {
      if (new_from == lp->sm_from && new_hint < lp->sm_hint) {
        lp->has_scope_marker = 1;
        lp->sm_from = new_from;
        lp->sm_pattern = new_pattern;
        lp->sm_matchdata = new_md;
        lp->sm_hint = new_hint;
      }
    }
  }
  return 0;
}

static VALUE rb_line_parser_update_scope_marker(VALUE self, VALUE rb_nsm) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  int new_from;
  VALUE new_pattern, new_md;
  new_from = NUM2INT(rb_hash_aref(rb_nsm, ID2SYM(rb_intern("from"))));
  new_pattern = rb_hash_aref(rb_nsm, ID2SYM(rb_intern("pattern")));
  new_md      = rb_hash_aref(rb_nsm, ID2SYM(rb_intern("md")));
  line_parser_update_scope_marker(lp, new_from, new_pattern, new_md);
  return Qnil;
}

/*       def current_scope_closes? */
/*         if current_scope.closing_regexp */
/*           if current_scope.start.line == line_num */
/*             thispos = [pos, current_scope.start.offset+1].max */
/*           else */
/*             thispos = pos */
/*           end */
/*           if md = current_scope.closing_regexp.match(@line, thispos) */
/*             from = md.begin(0) */
/*             { :from => from, :md => md, :pattern => :close_scope } */
/*           end */
/*         end */
/*       end */

static VALUE rb_line_parser_current_scope_closes(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  ScopeData *current_scope_data;
  VALUE rb_current_scope, rb_closing_regexp, rb_md, rb_line, rb_from, rb_nsm;
  int thispos;
  TextLoc start;
  current_scope_data = lp->current_scope->data;
  rb_current_scope = current_scope_data->rb_scope;
  rb_closing_regexp = rb_funcall(rb_current_scope, rb_intern("closing_regexp"), 0);
  if (rb_closing_regexp == Qnil)
    return Qnil;
  scope_start_loc(lp->current_scope, &start);
  thispos = start.offset+1;
  if (start.line != lp->line_num || lp->pos > thispos)
    thispos = lp->pos;
  rb_line = rb_iv_get(self, "@line");
  rb_md = rb_funcall(rb_closing_regexp, rb_intern("match"), 2, rb_line, INT2FIX(thispos));
  if (rb_md != Qnil) {
    rb_from = rb_funcall(rb_md, rb_intern("begin"), 1, INT2FIX(0));
    line_parser_update_scope_marker(lp, NUM2INT(rb_from), 
                                    ID2SYM(rb_intern("close_scope")), rb_md);
    return Qtrue;
  }
  return Qnil;
}

/*       def match_and_update_pattern(pattern) */
/*         if md = pattern.match.match(@line, pos) */
/*           from = md.begin(0) */
/*           update_scope_marker({ :from => from, :md => md, :pattern => pattern }) */
/*         end */
/*       end */
      
static VALUE rb_line_parser_match_pattern(VALUE self, VALUE rb_pattern) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
  VALUE rb_match_re, rb_md, rb_rest_line, rb_from, rb_scope_marker;
  int from;
  rb_match_re = rb_funcall(rb_pattern, rb_intern("match"), 0);
  if (rb_match_re != Qnil) {
    rb_rest_line = rb_iv_get(self, "@line");
    rb_md        = rb_funcall(rb_match_re, rb_intern("match"), 2, rb_rest_line, INT2FIX(lp->pos));
    if (rb_md != Qnil) {
      rb_from = rb_funcall(rb_md, rb_intern("begin"), 1, INT2FIX(0));
      rb_scope_marker = rb_hash_new();
      from = NUM2INT(rb_hash_aset(rb_scope_marker, ID2SYM(rb_intern("from")), rb_from));
      line_parser_update_scope_marker(lp, from, rb_pattern, rb_md);
      return rb_scope_marker;
    }
  }
  return Qnil;
}

/*       def scan_line */
/*         reset_scope_marker */
/*         current_scope_closes? */
/*         possible_patterns.each do |pattern| */
/*           if match_and_update_pattern(pattern) */
/*             matching_patterns << pattern if need_new_patterns */
/*           end */
/*         end           */
/*       end */
      
static VALUE rb_line_parser_scan_line(VALUE self) {
  LineParser *lp;
  VALUE rb_close_marker, rb_possible_patterns, rb_pattern, 
    rb_found, rb_matching_patterns, rb_need_new_patterns;
  int length, i;
  Data_Get_Struct(self, LineParser, lp);
  lp->has_scope_marker = 0; // reset_scope_marker
  rb_need_new_patterns = rb_funcall(self, rb_intern("need_new_patterns"), 0);
  rb_matching_patterns = rb_funcall(self, rb_intern("matching_patterns"), 0);
  rb_line_parser_current_scope_closes(self);
  rb_possible_patterns = rb_funcall(self, rb_intern("possible_patterns"), 0);
  length = RARRAY_LEN(rb_possible_patterns);
  for (i = 0; i < length; i++) {
    rb_pattern = rb_ary_entry(rb_possible_patterns, (long) i);
    rb_found = rb_line_parser_match_pattern(self, rb_pattern);
    if (rb_found != Qnil) {
      if (rb_need_new_patterns != Qnil)
        rb_ary_push(rb_matching_patterns, rb_pattern);
    }
  }
  return Qnil;
}

static VALUE mSyntaxExt, rb_mRedcar, rb_cEditView, rb_cParser;
static VALUE cScope, cTextLoc, cLineParser;

void Init_syntax_ext() {
  // utility functions are in SyntaxExt
  mSyntaxExt = rb_define_module("SyntaxExt");
  rb_define_module_function(mSyntaxExt, "colour_line_with_scopes", 
                            rb_colour_line_with_scopes, 3);
  rb_define_module_function(mSyntaxExt, "uncolour_scopes", 
                            rb_uncolour_scopes, 2);

  rb_mRedcar = rb_define_module ("Redcar");
  rb_cEditView = rb_eval_string("Redcar::EditView");
  //rb_define_class_under (rb_mRedcar, "EditView", rb_cObject);

  cTextLoc = rb_define_class_under(rb_cEditView, "TextLoc", rb_cObject);
  rb_define_alloc_func(cTextLoc, rb_textloc_alloc);
  rb_define_method(cTextLoc, "initialize", rb_textloc_init, 2);
  rb_define_method(cTextLoc, "line", rb_textloc_line, 0);
  rb_define_method(cTextLoc, "offset", rb_textloc_offset, 0);
  rb_define_method(cTextLoc, "==", rb_textloc_equal, 1);
  rb_define_method(cTextLoc, "<", rb_textloc_lt, 1);
  rb_define_method(cTextLoc, ">", rb_textloc_gt, 1);
  rb_define_method(cTextLoc, "<=", rb_textloc_lte, 1);
  rb_define_method(cTextLoc, ">=", rb_textloc_gte, 1);

  // the CScope class
  cScope = rb_define_class_under(rb_cEditView, "Scope", rb_cObject);
  rb_define_alloc_func(cScope, rb_scope_alloc);
  rb_define_method(cScope, "initialize", rb_scope_init, 1);
  rb_define_method(cScope, "cinit", rb_scope_cinit, 0);
  rb_define_method(cScope, "display",   rb_scope_print, 1);

/*   rb_define_method(cScope, "set_start", rb_scope_set_start, 2); */
/*   rb_define_method(cScope, "set_end",   rb_scope_set_end, 2);   */
/*   rb_define_method(cScope, "start", rb_scope_get_start, 0); */
/*   rb_define_method(cScope, "end",   rb_scope_get_end, 0); */

/*   rb_define_method(cScope, "set_open_end",    rb_scope_set_open_end, 2); */
/*   rb_define_method(cScope, "set_close_start", rb_scope_set_close_start, 2);   */
/*   rb_define_method(cScope, "open_end",    rb_scope_get_open_end, 0); */
/*   rb_define_method(cScope, "close_start", rb_scope_get_close_start, 0); */

  rb_define_method(cScope, "start_line",    rb_scope_get_start_line, 0);
  rb_define_method(cScope, "inner_start_line",    rb_scope_get_inner_start_line, 0);
  rb_define_method(cScope, "inner_end_line",    rb_scope_get_inner_end_line, 0);
  rb_define_method(cScope, "end_line",    rb_scope_get_end_line, 0);
  rb_define_method(cScope, "start_line_offset",    rb_scope_get_start_line_offset, 0);
  rb_define_method(cScope, "inner_start_line_offset",    rb_scope_get_inner_start_line_offset, 0);
  rb_define_method(cScope, "inner_end_line_offset",    rb_scope_get_inner_end_line_offset, 0);
  rb_define_method(cScope, "end_line_offset",    rb_scope_get_end_line_offset, 0);

  rb_define_method(cScope, "set_start_mark",    rb_scope_set_start_mark, 3);
  rb_define_method(cScope, "set_inner_start_mark",    rb_scope_set_inner_start_mark, 3);
  rb_define_method(cScope, "set_inner_end_mark",    rb_scope_set_inner_end_mark, 3);
  rb_define_method(cScope, "set_end_mark",    rb_scope_set_end_mark, 3);

  rb_define_method(cScope, "set_name",  rb_scope_set_name, 1);
  rb_define_method(cScope, "get_name",  rb_scope_get_name, 0);
/*   rb_define_method(cScope, "modified?", rb_scope_modified, 0); */
  rb_define_method(cScope, "overlaps?", rb_scope_overlaps, 1);
  rb_define_method(cScope, "on_line?",  rb_scope_active_on_line, 1);

  rb_define_method(cScope, "add_child",  rb_scope_add_child, 1);
  rb_define_method(cScope, "delete_child",  rb_scope_delete_child, 1);
  rb_define_method(cScope, "children",  rb_scope_get_children, 0);
  rb_define_method(cScope, "parent",  rb_scope_get_parent, 0);
  rb_define_method(cScope, "scope_at",  rb_scope_at, 1);
  rb_define_method(cScope, "first_child_after",  rb_scope_first_child_after, 2);
  rb_define_method(cScope, "clear_after",  rb_scope_clear_after, 1);
  rb_define_method(cScope, "clear_between",  rb_scope_clear_between, 2);
  rb_define_method(cScope, "clear_between_lines",  rb_scope_clear_between_lines, 2);
/*   rb_define_method(cScope, "shift_chars",  rb_scope_shift_chars, 3); */
  rb_define_method(cScope, "n_children",  rb_scope_n_children, 0);
  rb_define_method(cScope, "detach",  rb_scope_detach, 0);
  rb_define_method(cScope, "delete_any_on_line_not_in",  
                   rb_scope_delete_any_on_line_not_in, 3);
  rb_define_method(cScope, "clear_not_on_line",  rb_scope_clear_not_on_line, 1);
  rb_define_method(cScope, "remove_children_that_overlap", rb_scope_remove_children_that_overlap, 2);
  rb_define_method(cScope, "hierarchy_names",  rb_scope_hierarchy_names, 1);

  rb_cParser = rb_eval_string("Redcar::EditView::Parser");
  cLineParser = rb_define_class_under(rb_cParser, "LineParser", rb_cObject);
  rb_define_alloc_func(cLineParser, rb_line_parser_alloc);
  rb_define_method(cLineParser, "initialize", rb_line_parser_init, 5);
  rb_define_method(cLineParser, "line_length", rb_line_parser_line_length, 0);
  rb_define_method(cLineParser, "line_num", rb_line_parser_line_num, 0);
  rb_define_method(cLineParser, "pos", rb_line_parser_get_pos, 0);
  rb_define_method(cLineParser, "pos=", rb_line_parser_set_pos, 1);
  rb_define_method(cLineParser, "current_scope", rb_line_parser_get_current_scope, 0);
  rb_define_method(cLineParser, "current_scope=", rb_line_parser_set_current_scope, 1);
  rb_define_method(cLineParser, "starting_child", rb_line_parser_get_starting_child, 0);
  rb_define_method(cLineParser, "starting_child=", rb_line_parser_set_starting_child, 1);
  rb_define_method(cLineParser, "reset_scope_marker", rb_line_parser_reset_scope_marker, 0);
  rb_define_method(cLineParser, "any_markers?", rb_line_parser_any_scope_markers, 0);
  rb_define_method(cLineParser, "get_scope_marker", rb_line_parser_get_scope_marker, 0);
  rb_define_method(cLineParser, "update_scope_marker", rb_line_parser_update_scope_marker, 1);
  rb_define_method(cLineParser, "current_scope_closes?", rb_line_parser_current_scope_closes, 0);
  rb_define_method(cLineParser, "match_pattern", rb_line_parser_match_pattern, 1);
  rb_define_method(cLineParser, "scan_line", rb_line_parser_scan_line, 0);

}

