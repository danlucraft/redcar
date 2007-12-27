
#include "ruby.h"
#include <gtk/gtk.h>
#include <glib.h>

#include "textloc.h"

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

typedef struct ScopeData_ {
  TextLoc start;
  TextLoc end;
  char* name;
} ScopeData;

typedef GNode Scope;

static VALUE scope_init(VALUE self) {
  return self;
}

int scope_free_data(Scope* scope) {
  //  free(((ScopeData *) scope->data)->name);
  // don't free the name because it's likely an RSTRING
  free(scope->data);
  return FALSE;
}

void scope_destroy(Scope* scope) {
  g_node_traverse(scope, G_IN_ORDER, G_TRAVERSE_ALL, -1,
		  (GNodeTraverseFunc) scope_free_data, NULL);
  g_node_destroy((gpointer) scope);
  return;
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
  obj = Data_Wrap_Struct(klass, 0, scope_destroy, scope);
  return obj;
}

static VALUE scope_print(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  char *name = "noname";
  if (sd->name)
    name = sd->name;
  printf("<scope %s (%d,%d)-(%d,%d)>\n", 
	 name,
  	 sd->start.line, sd->start.offset, sd->end.line,
  	 sd->end.offset);
  return Qnil;
}

static VALUE scope_set_start(VALUE self, VALUE s_line, VALUE s_off) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  sd->start.line = FIX2INT(s_line);
  sd->start.offset = FIX2INT(s_off);
  return Qnil;
}

static VALUE scope_set_end(VALUE self, VALUE e_line, VALUE e_off) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  sd->end.line = FIX2INT(e_line);
  sd->end.offset = FIX2INT(e_off);
  return Qnil;
}

static VALUE scope_get_start(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->start))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->start.line), INT2FIX(sd->start.offset));
}

static VALUE scope_get_end(VALUE self) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->end))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->end.line), INT2FIX(sd->end.offset));
}

static VALUE scope_set_name(VALUE self, VALUE name) {
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  sd->name = RSTRING_PTR(name); // what if the string gets garbage collected?
                                // This shouldn't happen in Redcar because the grammars
                                // are always in memory.
  return Qnil;
}

// Boolean scope methods

static VALUE scope_active_on_line(VALUE self, VALUE line_num) {
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

static VALUE mSyntaxExt;
static VALUE cScope;

void Init_syntax_ext() {
  // utility functions are in SyntaxExt
  mSyntaxExt = rb_define_module("SyntaxExt");
  rb_define_module_function(mSyntaxExt, "set_window_title", set_window_title, 2);

  // the CScope class
  cScope = rb_define_class("CScope", rb_cObject);
  rb_define_alloc_func(cScope, scope_alloc);
  rb_define_method(cScope, "initialize", scope_init, 0);
  rb_define_method(cScope, "display",   scope_print, 0);
  rb_define_method(cScope, "set_start", scope_set_start, 2);
  rb_define_method(cScope, "set_end",   scope_set_end, 2);  
  rb_define_method(cScope, "get_start", scope_get_start, 0);
  rb_define_method(cScope, "get_end",   scope_get_end, 0);
  rb_define_method(cScope, "set_name",  scope_set_name, 1);
  rb_define_method(cScope, "overlaps?", scope_overlaps, 1);
  rb_define_method(cScope, "on_line?",  scope_active_on_line, 1);
}
