
#include "scope.h"
#include <glib.h>
#include <string.h>

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

int scope_add_child(Scope* parent, Scope* new_child, Scope* starting_child) {
  Scope *child;
  TextLoc nc_start, nc_end;
  TextLoc c_start, c_end;
  scope_start_loc(new_child, &nc_start);
  scope_end_loc(new_child, &nc_end);
  if (g_node_n_children(parent) == 0) {
		//		printf(".");
    g_node_append(parent, new_child);
    return 1;
  }
  Scope *insert_after = NULL;
  int i;
  if (starting_child && starting_child->parent == parent) {
		//		printf(",");
    child = starting_child;
  }
  else {
		//		printf(":");
    child = g_node_first_child(parent);
  }
  while(child != NULL) {	
    scope_start_loc(child, &c_start);
    scope_end_loc(child, &c_end);
		//		printf("-");
    if (textloc_lte(&c_start, &nc_start))
      insert_after = child;
		if (textloc_gte(&c_start, &nc_end))
			child = NULL;
		else
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
  sd->numcolourings = 0;
  sd->open = 0;
  sd->bg_color = NULL;
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

static VALUE rb_scope_set_open(VALUE self, VALUE rb_open) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (rb_open == Qtrue)
    sd->open = 1;
  else
    sd->open = 0;
  return Qnil;
}

static VALUE rb_scope_get_open(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (sd->open)
    return Qtrue;
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

/* Find the scope at text location.  */
Scope* scope_at(Scope* s, TextLoc* loc) {
  Scope *scope, *child;
  ScopeData *sd = s->data;
  int i;

  TextLoc s_start, s_end;
  TextLoc c_start, c_end;
  scope_start_loc(s, &s_start);
  scope_end_loc(s, &s_end);
  if (textloc_lte(&s_start, loc) || G_NODE_IS_ROOT(s)) {
    if (textloc_gte(&s_end, loc)) {
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

Scope* scope_first_child_after(Scope* scope, TextLoc *loc, Scope* starting_child) {
  Scope *child;
  TextLoc c_start;
  if (g_node_n_children(scope) == 0)
    return NULL;
  if (starting_child && starting_child->parent == scope) {
    child = starting_child;
  }
  else {
    child = g_node_first_child(scope);
  }
  while (child != NULL) {
    scope_start_loc(child, &c_start);
    if (textloc_gte(&c_start, loc))
      return child;
    child = g_node_next_sibling(child);
  }
  return NULL;
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
	child = scope_first_child_after(s, loc, starting_child);
	if (child == NULL)
		return Qnil;
	else {
		sd = child->data;
		return sd->rb_scope;
	}
}

static VALUE rb_scope_add_child(VALUE self, VALUE c_scope, VALUE rb_starting_child) {
  if (self == Qnil || c_scope == Qnil)
    printf("rb_scope_add_child(nil, or nil)");
  Scope *sp, *sc, *lc, *s_start;
  ScopeData *sdp, *sdc, *lcd, *current_data;
  Data_Get_Struct(self, Scope, sp);
  Data_Get_Struct(c_scope, Scope, sc);
  if (rb_starting_child != Qnil)
    Data_Get_Struct(rb_starting_child, Scope, s_start);
  if (scope_add_child(sp, sc, s_start))
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
    if (!pd->rb_scope)
      printf("parent lacking rb_scope!!");
    return pd->rb_scope;
  }
  return Qnil;
}

static VALUE rb_scope_get_priority(VALUE self) {
  Scope *scope;
  Data_Get_Struct(self, Scope, scope);
  return INT2FIX(scope_get_priority(scope));
}

int scope_get_priority(Scope* scope) {
  if (scope->parent)
    return scope_get_priority(scope->parent)+1;
  else
    return 1;
}

int delete_marks(GtkTextBuffer *buffer, Scope *scope) {
  ScopeData* sd = scope->data;
  if(sd->start_mark)
    gtk_text_buffer_delete_mark(buffer, sd->start_mark);
  if(sd->inner_start_mark)
    gtk_text_buffer_delete_mark(buffer, sd->inner_start_mark);
  if(sd->end_mark)
    gtk_text_buffer_delete_mark(buffer, sd->end_mark);
  if(sd->inner_end_mark)
    gtk_text_buffer_delete_mark(buffer, sd->inner_end_mark);
    
  Scope *child;
  child = g_node_first_child(scope);
  while(child != NULL) {
    delete_marks(buffer, child);
    child = g_node_next_sibling(child);
  }
  return 0;
}

char* scope_nearest_bg_color(Scope *scope) {
  ScopeData* sd = scope->data;
  if (sd->bg_color == NULL) {
    if (G_NODE_IS_ROOT(scope))
      return NULL;
    else
      return scope_nearest_bg_color(scope->parent);
  }
  return sd->bg_color;
}

static VALUE rb_scope_nearest_bg_color(VALUE self) {
  Scope* scope;
  Data_Get_Struct(self, Scope, scope);
  char* bg_color = scope_nearest_bg_color(scope);
  if(bg_color == NULL)
    return Qnil;
  else
    return rb_str_new2(bg_color);
}

static VALUE rb_scope_get_bg_color(VALUE self) {
  Scope* scope;
  Data_Get_Struct(self, Scope, scope);
  ScopeData* sd = scope->data;
  if (sd->bg_color != NULL)
    return rb_str_new2(sd->bg_color);
  else
    return Qnil;
}

static VALUE rb_scope_set_bg_color(VALUE self, VALUE rb_bg_color) {
  Scope *scope;
  Data_Get_Struct(self, Scope, scope);
  ScopeData * sd = scope->data;
  sd->bg_color = RSTRING_PTR(rb_bg_color);
  return rb_bg_color;
}

static VALUE cScope, rb_cEditView;

void Init_scope() {
  rb_cEditView = rb_eval_string("Redcar::EditView");

  // the CScope class
  cScope = rb_define_class_under(rb_cEditView, "Scope", rb_cObject);
  rb_define_alloc_func(cScope, rb_scope_alloc);
  rb_define_method(cScope, "initialize", rb_scope_init, 1);
  rb_define_method(cScope, "cinit", rb_scope_cinit, 0);
  rb_define_method(cScope, "display",   rb_scope_print, 1);

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
  rb_define_method(cScope, "set_open",  rb_scope_set_open, 1);
  rb_define_method(cScope, "get_open",  rb_scope_get_open, 0);
/*   rb_define_method(cScope, "modified?", rb_scope_modified, 0); */
  rb_define_method(cScope, "overlaps?", rb_scope_overlaps, 1);
  rb_define_method(cScope, "on_line?",  rb_scope_active_on_line, 1);

  rb_define_method(cScope, "add_child",  rb_scope_add_child, 2);
  rb_define_method(cScope, "delete_child",  rb_scope_delete_child, 1);
  rb_define_method(cScope, "children",  rb_scope_get_children, 0);
  rb_define_method(cScope, "parent",  rb_scope_get_parent, 0);
  rb_define_method(cScope, "priority",  rb_scope_get_priority, 0);
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

  rb_define_method(cScope, "bg_color",  rb_scope_get_bg_color, 0);
  rb_define_method(cScope, "bg_color=",  rb_scope_set_bg_color, 1);
  rb_define_method(cScope, "nearest_bg_color",  rb_scope_nearest_bg_color, 0);
}
