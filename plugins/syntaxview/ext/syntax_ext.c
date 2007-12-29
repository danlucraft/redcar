
#include "ruby.h"
#include <gtk/gtk.h>
#include <glib.h>

#include "textloc.h"

// ----- Get a GTK object from a Ruby-Gnome object ----
typedef struct {
    VALUE self;
    GObject* gobj;
    void* cinfo;
    gboolean destroyed;
} gobj_holder;

GObject* get_gobject(VALUE rbgobj) {
  gobj_holder *gh;
  Data_Get_Struct(rbgobj, gobj_holder, gh);
  return gh->gobj;
}

static VALUE set_window_title(VALUE self, VALUE rbgobj, VALUE title) {
  GtkWidget *window = (GtkWidget *) get_gobject(rbgobj);
  gtk_window_set_title(GTK_WINDOW(window), RSTRING_PTR(title));
  return self;
}

// ----- Scope object

typedef struct ScopeData_ {
  TextLoc start;
  TextLoc end;
  char* name;
  VALUE rb_scope;
  VALUE rb_rb_scope;
} ScopeData;

typedef GNode Scope;

static VALUE scope_init(VALUE self, VALUE rb_rb_scope) {
  Scope *scope;
  Data_Get_Struct(self, Scope, scope);
  ScopeData *sd = scope->data;
  sd->rb_rb_scope = rb_rb_scope;
  return self;
}

int scope_free_data(Scope* scope) {
  //  free(((ScopeData *) scope->data)->name);
  // don't free the name because it's likely an RSTRING
  free(scope->data);
  return FALSE;
}

void scope_destroy(Scope* scope) {
  scope_free_data(scope);
  //  g_node_destroy((gpointer) scope);
  return;
}

void scope_mark(Scope* scope) {
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

static VALUE scope_alloc(VALUE klass) {
  Scope *scope;
  VALUE obj;
  ScopeData* scope_data = malloc(sizeof(ScopeData));
  (scope_data->start).line = -1;
  (scope_data->start).offset = -1;
  (scope_data->end).line = -1;
  (scope_data->end).offset = -1;
  (scope_data->name) = NULL;
  scope = g_node_new((gpointer) scope_data);
  obj = Data_Wrap_Struct(klass, scope_mark, scope_destroy, scope);
  scope_data->rb_scope = obj;
  return obj;
}

static VALUE scope_print(VALUE self, VALUE indent) {
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
  printf("<scope %p %s (%d,%d)-(%d,%d)>\n", 
	 s, name,
  	 sd->start.line, sd->start.offset, sd->end.line,
  	 sd->end.offset);
  for (i = 0; i < g_node_n_children(s); i++) {
    child = g_node_nth_child(s, i);
    sd = child->data;
    scope_print(sd->rb_scope, INT2FIX(in+2));
  }
  return Qnil;
}

static VALUE scope_set_start(VALUE self, VALUE s_line, VALUE s_off) {
  if (self == Qnil || s_line == Qnil || s_off == Qnil)
    printf("scope_set_start(nil, or nil, or nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  sd->rb_scope = self;
  sd->start.line = FIX2INT(s_line);
  sd->start.offset = FIX2INT(s_off);
  return Qnil;
}

static VALUE scope_set_end(VALUE self, VALUE e_line, VALUE e_off) {
  if (self == Qnil || e_line == Qnil ||e_off == Qnil)
    printf("scope_set_end(nil, or nil, or nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  sd->end.line = FIX2INT(e_line);
  sd->end.offset = FIX2INT(e_off);
  return Qnil;
}

static VALUE scope_get_start(VALUE self) {
  if (self == Qnil)
    printf("scope_get_start(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->start))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->start.line), INT2FIX(sd->start.offset));
}

static VALUE scope_get_end(VALUE self) {
  if (self == Qnil)
    printf("scope_get_end(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->end))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->end.line), INT2FIX(sd->end.offset));
}

static VALUE scope_set_name(VALUE self, VALUE name) {
  if (self == Qnil)
    printf("scope_set_name(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (name == Qnil)
    sd->name = NULL;
  else
    sd->name = RSTRING_PTR(name); // what if the string gets garbage collected?
                                  // This shouldn't happen in Redcar because the grammars
                                  // are always in memory.
  return Qnil;
}

static VALUE scope_get_name(VALUE self) {
  if (self == Qnil)
    printf("scope_get_name(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (sd->name)
    return rb_str_new2(sd->name);
  else
    return Qnil;
}

// Boolean scope methods

static VALUE scope_active_on_line(VALUE self, VALUE line_num) {
  if (self == Qnil || line_num == Qnil)
    printf("scope_active_on_line(nil, or nil)");
  int num = FIX2INT(line_num);
  Scope *s;
  ScopeData *sd;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  if (sd->start.line <= num)
    if (!TEXTLOC_VALID(sd->end) || sd->end.line >= num)
      return Qtrue;
  return Qfalse;
}

static VALUE scope_overlaps(VALUE self, VALUE other) {
  if (self == Qnil || other == Qnil)
    printf("scope_overlaps(nil, or nil)");
  Scope *s1, *s2;
  ScopeData *sd1, *sd2;
  Data_Get_Struct(self, Scope, s1);
  Data_Get_Struct(other, Scope, s2);

  sd1 = s1->data;
  sd2 = s2->data;

  // sd1     +---
  // sd2  +---
  if (TEXTLOC_GTE(sd1->start, sd2->start)) {
    if (!TEXTLOC_VALID(sd2->end))
      return Qtrue;
    if (TEXTLOC_LT(sd1->start, sd2->end))
      return Qtrue;
    return Qfalse;
  }
  // sd1 +----
  // sd2   +---
  if (!TEXTLOC_VALID(sd1->end))
    return Qtrue;
  if (TEXTLOC_GT(sd1->end, sd2->start) && TEXTLOC_LT(sd1->end, sd2->end))
    return Qtrue;
  return Qfalse;
}

// Scope children methods

static VALUE scope_add_child(VALUE self, VALUE c_scope) {
  if (self == Qnil || c_scope == Qnil)
    printf("scope_add_child(nil, or nil)");
  Scope *sp, *sc, *lc;
  ScopeData *sdp, *sdc, *lcd, *current_data;
  Data_Get_Struct(self, Scope, sp);
  Data_Get_Struct(c_scope, Scope, sc);

  sdp = sp->data;
  sdc = sc->data;
  if (g_node_n_children(sp) == 0) {
    g_node_append(sp, sc);
    return Qtrue;
  }
  else {
    lc = g_node_last_child(sp);
    lcd = lc->data;
    if (TEXTLOC_VALID(lcd->end) &&
	TEXTLOC_GTE(sdc->start, lcd->end)) {
      g_node_append(sp, sc);
      return Qtrue;
    }
  }
  int insert_index = 0;
  int i;
  Scope *current = NULL;
  for (i = 0; i < g_node_n_children(sp); i++) {
    current = g_node_nth_child(sp, i);
    current_data = current->data;
    if (TEXTLOC_LTE(current_data->start, sdc->start))
      insert_index = i+1;
  }
  g_node_insert(sp, insert_index, sc);
  return Qtrue;
}

static VALUE scope_clear_after(VALUE self, VALUE rb_loc) {
  if (self == Qnil || rb_loc == Qnil)
    printf("scope_clear_after(nil, or nil)");
  TextLoc loc;
  loc.line = FIX2INT(rb_iv_get(rb_loc, "@line"));
  loc.offset = FIX2INT(rb_iv_get(rb_loc, "@offset"));
  Scope *s, *c;
  ScopeData *sd, *sdc;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  if (TEXTLOC_VALID(sd->end) && TEXTLOC_GT(sd->end, loc)) {
    sd->end.line = -1;
    sd->end.offset = -1;
  }
  int i;
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    sdc = c->data;
    if (TEXTLOC_GTE(sdc->start, loc)) {
      g_node_unlink(c);
      i -= 1;
    } else {
      scope_clear_after(sdc->rb_scope, rb_loc);
    }
  }
  return Qtrue;
}

static VALUE scope_n_children(VALUE self) {
  if (self == Qnil)
    printf("scope_n_children(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  return INT2FIX(g_node_n_children(s));
}

static VALUE scope_clear_between(VALUE self, VALUE rb_from, VALUE rb_to) {
  if (self == Qnil || rb_from == Qnil || rb_to == Qnil)
    printf("scope_clear_between(nil, or nil, or nil)");
  TextLoc from, to;
  from.line = FIX2INT(rb_iv_get(rb_from, "@line"));
  from.offset = FIX2INT(rb_iv_get(rb_from, "@offset"));
  to.line = FIX2INT(rb_iv_get(rb_to, "@line"));
  to.offset = FIX2INT(rb_iv_get(rb_to, "@offset"));
  Scope *s, *c;
  ScopeData *sd, *sdc;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  if (TEXTLOC_VALID(sd->end) && TEXTLOC_GTE(sd->end, from) &&
      TEXTLOC_LT(sd->end, to)) {
    sd->end.line = -1;
    sd->end.offset = -1;
  }
  int i;
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    sdc = c->data;
    if ((TEXTLOC_GTE(sdc->start, from) && 
	 TEXTLOC_LT(sdc->start, to)) ||
	(TEXTLOC_VALID(sdc->end) && 
	 TEXTLOC_GTE(sdc->end, from) &&
	 TEXTLOC_LT(sdc->end, to))) {
      g_node_unlink(c);
      i -= 1;
    } else {
      scope_clear_between(sdc->rb_scope, rb_from, rb_to);
    }
  }
  return Qtrue;
}

static VALUE scope_clear_between_lines(VALUE self, VALUE rb_from, VALUE rb_to) {
  if (self == Qnil || rb_from == Qnil || rb_to == Qnil)
    printf("scope_clear_between_lines(nil, or nil, or nil)");
  int from = FIX2INT(rb_from);
  int to   = FIX2INT(rb_to);
  Scope *s, *c;
  ScopeData *sd, *sdc;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  if (TEXTLOC_VALID(sd->end) && sd->end.line >= from &&
      sd->end.line <= to) {
    sd->end.line = -1;
    sd->end.offset = -1;
  }
  int i;
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    sdc = c->data;
    if (sdc->start.line >= from && sdc->start.line <= to) {
      g_node_unlink(c);
      i -= 1;
    } else {
      scope_clear_between_lines(sdc->rb_scope, rb_from, rb_to);
    }
  }
  return Qtrue;
}

static VALUE scope_detach(VALUE self) {
  if (self == Qnil)
    printf("scope_detach(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  if (s->parent)
    g_node_unlink(s);
  return Qtrue;
}

static VALUE scope_delete_any_on_line_not_in(VALUE self, VALUE line_num, VALUE scopes) {
  if (self == Qnil || line_num == Qnil || scopes == Qnil)
    printf("scope_delete_any_on_line_not_in(nil, or nil, or nil)");
  Scope *s, *c, *s1;
  ScopeData *sdc;
  Data_Get_Struct(self, Scope, s);
  int num = FIX2INT(line_num);
  int i, j, remove;
  VALUE rs1;
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    sdc = c->data;
    if (sdc->start.line == num) {
      remove = TRUE;
      for (j = 0; j < RARRAY(scopes)->len; j++) {
	rs1 = rb_ary_entry(scopes, (long) j);
	rs1 = rb_funcall(rs1, rb_intern("cscope"), 0);
	Data_Get_Struct(rs1, Scope, s1);
	if (c == s1)
	  remove = FALSE;
      }
      if (remove) {
	g_node_unlink(c);
	i -= 1;
      }
    }
  }
  return Qtrue;
}

static VALUE scope_clear_not_on_line(VALUE self, VALUE rb_num) {
  if (self == Qnil || rb_num == Qnil)
    printf("scope_clear_not_on_line(nil, or nil)");
  Scope *s, *c;
  ScopeData *sd, *sdc;
  Data_Get_Struct(self, Scope, s);
  int i;
  int num = FIX2INT(rb_num);
  for (i = 0; i < g_node_n_children(s); i++) {
    c = g_node_nth_child(s, i);
    sdc = c->data;
    if (scope_active_on_line(sdc->rb_scope, rb_num) == Qfalse) {
      g_node_unlink(c);
      i -= 1;
    }
  }
}

static VALUE scope_delete_child(VALUE self, VALUE rb_scope) {
  if (self == Qnil || rb_scope == Qnil)
    printf("scope_delete_child(nil, or nil)");
  Scope *parent, *child;
  Data_Get_Struct(self, Scope, parent);
  VALUE rb_cscope = rb_funcall(rb_scope, rb_intern("cscope"), 0);
  Data_Get_Struct(rb_cscope, Scope, child);
  if (child->parent == parent)
    g_node_unlink(child);
  return Qtrue;
}

static VALUE scope_get_children(VALUE self) {
  if (self == Qnil)
    printf("scope_get_children(nil)");
  Scope *scope, *child;
  ScopeData *sd, *cd;
  Data_Get_Struct(self, Scope, scope);
  int i;
  VALUE ary = rb_ary_new2(g_node_n_children(scope));
  for (i = 0; i < g_node_n_children(scope); i++) {
    child = g_node_nth_child(scope, i);
    cd = child->data;
    rb_ary_store(ary, i, cd->rb_rb_scope);
  }
  return ary;
}

static VALUE scope_get_parent(VALUE self) {
  if (self == Qnil)
    printf("scope_get_parent(nil)");
  Scope *scope, *parent;
  ScopeData *sd, *pd;
  Data_Get_Struct(self, Scope, scope);
  parent = scope->parent;
  if (parent) {
    pd = parent->data;
    return pd->rb_rb_scope;
  }
  return Qnil;
}

static VALUE mSyntaxExt;
static VALUE cScope;

void Init_syntax_ext() {
  // utility functions are in SyntaxExt
  mSyntaxExt = rb_define_module("SyntaxExt");
  rb_define_module_function(mSyntaxExt, "set_window_title", set_window_title, 2);

  // the CScope class
  cScope = rb_define_class("CScope", rb_cObject);
  rb_define_alloc_func(cScope, scope_alloc);
  rb_define_method(cScope, "initialize", scope_init, 1);
  rb_define_method(cScope, "display",   scope_print, 1);
  rb_define_method(cScope, "set_start", scope_set_start, 2);
  rb_define_method(cScope, "set_end",   scope_set_end, 2);  
  rb_define_method(cScope, "get_start", scope_get_start, 0);
  rb_define_method(cScope, "get_end",   scope_get_end, 0);
  rb_define_method(cScope, "set_name",  scope_set_name, 1);
  rb_define_method(cScope, "get_name",  scope_get_name, 0);
  rb_define_method(cScope, "overlaps?", scope_overlaps, 1);
  rb_define_method(cScope, "on_line?",  scope_active_on_line, 1);

  rb_define_method(cScope, "add_child",  scope_add_child, 1);
  rb_define_method(cScope, "delete_child",  scope_delete_child, 1);
  rb_define_method(cScope, "get_children",  scope_get_children, 0);
  rb_define_method(cScope, "get_parent",  scope_get_parent, 0);
  rb_define_method(cScope, "clear_after",  scope_clear_after, 1);
  rb_define_method(cScope, "clear_between",  scope_clear_between, 2);
  rb_define_method(cScope, "clear_between_lines",  scope_clear_between_lines, 2);
  rb_define_method(cScope, "n_children",  scope_n_children, 0);
  rb_define_method(cScope, "detach",  scope_detach, 0);
  rb_define_method(cScope, "delete_any_on_line_not_in",  scope_delete_any_on_line_not_in, 2);
  rb_define_method(cScope, "clear_not_on_line",  scope_clear_not_on_line, 1);
}
