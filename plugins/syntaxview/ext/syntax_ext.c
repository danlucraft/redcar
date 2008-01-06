
#include "ruby.h"
#include <gtk/gtk.h>
#include <glib.h>
#include <string.h>

#include "textloc.h"

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

static VALUE set_window_title(VALUE self, VALUE rbgobj, VALUE title) {
  GtkWidget *window = (GtkWidget *) get_gobject(rbgobj);
  gtk_window_set_title(GTK_WINDOW(window), RSTRING_PTR(title));
  return self;
}

// ----- Scope object

typedef struct ScopeData_ {
  TextLoc start;
  TextLoc end;
  TextLoc open_end;
  TextLoc close_start;
  char* name;
  VALUE rb_scope;
} ScopeData;

typedef GNode Scope;

void scope_set_start(Scope* scope, int line, int off) {
  ScopeData *sd = scope->data;
  sd->start.line = line;
  sd->start.offset = off;
  return;
}

void scope_set_end(Scope* scope, int line, int off) {
  ScopeData *sd = scope->data;
  sd->end.line = line;
  sd->end.offset = off;
  return;
}

void scope_get_start(Scope* scope, TextLoc* loc) {
  ScopeData *sd = scope->data;
  loc->line = sd->start.line;
  loc->offset = sd->start.offset;
  return;
}

void scope_get_end(Scope* scope, TextLoc* loc) {
  ScopeData *sd = scope->data;
  loc->line = sd->end.line;
  loc->offset = sd->end.offset;
  return;
}

void scope_set_open_end(Scope* scope, int line, int off) {
  ScopeData *sd = scope->data;
  sd->open_end.line = line;
  sd->open_end.offset = off;
  return;
}

void scope_set_close_start(Scope* scope, int line, int off) {
  ScopeData *sd = scope->data;
  sd->close_start.line = line;
  sd->close_start.offset = off;
  return;
}

void scope_get_open_end(Scope* scope, TextLoc* loc) {
  ScopeData *sd = scope->data;
  loc->line = sd->open_end.line;
  loc->offset = sd->open_end.offset;
  return;
}

void scope_get_close_start(Scope* scope, TextLoc* loc) {
  ScopeData *sd = scope->data;
  loc->line = sd->close_start.line;
  loc->offset = sd->close_start.offset;
  return;
}

static VALUE rb_scope_init(VALUE self, VALUE options) {
  Scope *scope;
  Data_Get_Struct(self, Scope, scope);
  ScopeData *sd = scope->data;
  sd->rb_scope = self;
  rb_funcall(self, rb_intern("initialize2"), 1, options);
  return self;
}

int scope_free_data(Scope* scope) {
  //  free(((ScopeData *) scope->data)->name);
  // don't free the name because it's likely an RSTRING
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
  (scope_data->start).line = -1;
  (scope_data->start).offset = -1;
  (scope_data->end).line = -1;
  (scope_data->end).offset = -1;
  (scope_data->name) = NULL;
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
  printf("<scope %p %s (%d,%d)-(%d,%d)>\n", 
	 s, name,
  	 sd->start.line, sd->start.offset, sd->end.line,
  	 sd->end.offset);
  for (i = 0; i < g_node_n_children(s); i++) {
    child = g_node_nth_child(s, i);
    sd = child->data;
    rb_scope_print(sd->rb_scope, INT2FIX(in+2));
  }
  return Qnil;
}

static VALUE rb_scope_set_start(VALUE self, VALUE line, VALUE off) {
  if (self == Qnil || line == Qnil || off == Qnil)
    printf("rb_scope_set_start(nil, or nil, or nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  scope_set_start(s, FIX2INT(line), FIX2INT(off));
  return Qnil;
}

static VALUE rb_scope_set_end(VALUE self, VALUE line, VALUE off) {
  if (self == Qnil || line == Qnil ||off == Qnil)
    printf("rb_scope_set_end(nil, or nil, or nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  scope_set_end(s, FIX2INT(line), FIX2INT(off));
  return Qnil;
}

static VALUE rb_scope_get_start(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_get_start(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->start))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->start.line), INT2FIX(sd->start.offset));
}

static VALUE rb_scope_get_end(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_get_end(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->end))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->end.line), INT2FIX(sd->end.offset));
}

static VALUE rb_scope_set_open_end(VALUE self, VALUE line, VALUE off) {
  if (self == Qnil || line == Qnil || off == Qnil)
    printf("rb_scope_set_open_end(nil, or nil, or nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  scope_set_open_end(s, FIX2INT(line), FIX2INT(off));
  return Qnil;
}

static VALUE rb_scope_set_close_start(VALUE self, VALUE line, VALUE off) {
  if (self == Qnil || line == Qnil || off == Qnil)
    printf("rb_scope_set_close_start(nil, or nil, or nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  scope_set_close_start(s, FIX2INT(line), FIX2INT(off));
  return Qnil;
}

static VALUE rb_scope_get_open_end(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_get_open_end(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->open_end))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->open_end.line), INT2FIX(sd->open_end.offset));
}

static VALUE rb_scope_get_close_start(VALUE self) {
  if (self == Qnil)
    printf("rb_scope_get_close_start(nil)");
  Scope *s;
  Data_Get_Struct(self, Scope, s);
  ScopeData *sd = s->data;
  if (!TEXTLOC_VALID(sd->close_start))
    return Qnil;
  return rb_funcall(rb_cObject, rb_intern("TextLoc"),
		    2, INT2FIX(sd->close_start.line), INT2FIX(sd->close_start.offset));
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
  ScopeData *sd;
  Data_Get_Struct(self, Scope, s);
  sd = s->data;
  if (sd->start.line <= num)
    if (!TEXTLOC_VALID(sd->end) || sd->end.line >= num)
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
  if (TEXTLOC_GT(sd1->end, sd2->start))
    return Qtrue;
  return Qfalse;
}

// Scope children methods

static VALUE rb_scope_add_child(VALUE self, VALUE c_scope) {
  if (self == Qnil || c_scope == Qnil)
    printf("rb_scope_add_child(nil, or nil)");
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

static VALUE rb_scope_clear_after(VALUE self, VALUE rb_loc) {
  if (self == Qnil || rb_loc == Qnil)
    printf("rb_scope_clear_after(nil, or nil)");
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

static VALUE rb_scope_clear_between_lines(VALUE self, VALUE rb_from, VALUE rb_to) {
  if (self == Qnil || rb_from == Qnil || rb_to == Qnil)
    printf("rb_scope_clear_between_lines(nil, or nil, or nil)");
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
      rb_scope_clear_between_lines(sdc->rb_scope, rb_from, rb_to);
    }
  }
  return Qtrue;
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

static VALUE rb_scope_delete_any_on_line_not_in(VALUE self, 
								VALUE line_num, VALUE scopes) {
  if (self == Qnil || line_num == Qnil || scopes == Qnil)
    printf("rb_scope_delete_any_on_line_not_in(nil, or nil, or nil)");
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
    if (scope_active_on_line(sdc->rb_scope, rb_num) == Qfalse) {
      g_node_unlink(c);
      i -= 1;
    }
  }
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

void scope_get_start_iter(Scope* scope, GtkTextBuffer* buffer, 
			  GtkTextIter* start_iter, int inner) {
  ScopeData* sd = scope->data;
  GtkTextIter sl;
  int offset;
  gtk_text_buffer_get_iter_at_line_offset(buffer, &sl, sd->start.line, 0);
  if (inner)
    offset = (int) gtk_text_iter_get_offset(&sl) + minify(sd->open_end.offset);
  else
    offset = (int) gtk_text_iter_get_offset(&sl) + minify(sd->start.offset);
  gtk_text_buffer_get_iter_at_offset(buffer, start_iter, offset);
  return;
}

void scope_get_end_iter(Scope* scope, GtkTextBuffer* buffer, 
			GtkTextIter* end_iter, int inner) {
  ScopeData* sd = scope->data;
  GtkTextIter sl, sel; // start of start line, start of end line
  int offset, so, eo, len;
  gtk_text_buffer_get_iter_at_line_offset(buffer, &sl, sd->start.line, 0);
  if (inner) {
    if (TEXTLOC_VALID(sd->end)) {
      gtk_text_buffer_get_iter_at_line_offset(buffer, &sel, sd->close_start.line, 0);
      offset = (int) gtk_text_iter_get_offset(&sel) + minify(sd->close_start.offset);
    }
    else {
      gtk_text_buffer_get_iter_at_line_offset(buffer, &sel, sd->open_end.line+1, 0);
      offset = gtk_text_iter_get_offset(&sel);
      so = gtk_text_iter_get_offset(&sl);
      if (offset == so)
	offset = gtk_text_buffer_get_char_count(buffer);
    }
  }
  else {
    if (TEXTLOC_VALID(sd->end)) {
      gtk_text_buffer_get_iter_at_line_offset(buffer, &sel, sd->end.line, 0);
      offset = (int) gtk_text_iter_get_offset(&sel) + minify(sd->end.offset);
    }
    else {
      gtk_text_buffer_get_iter_at_line_offset(buffer, &sel, sd->start.line+1, 0);
      offset = gtk_text_iter_get_offset(&sel);
      so = gtk_text_iter_get_offset(&sl);
      if (offset == so)
	offset = gtk_text_buffer_get_char_count(buffer);
    }
  }
  gtk_text_buffer_get_iter_at_offset(buffer, end_iter, offset);
  return;
}
#define xtod(c) ((c>='0' && c<='9') ? c-'0' : ((c>='A' && c<='F') ? c-'A'+10 : ((c>='a' && c<='f') ? c-'a'+10 : 0)))

void clean_colour(char* in, char* out) {
  int r, g, b, t;
  if (strlen(in) == 7)
    strcpy(out, in);
  else {
    in[7] = '\0';
    strcpy(out, in);
  }
/*     r = xtod(in[1])*16+xtod(in[2]); */
/*     g = xtod(in[3])*16+xtod(in[4]); */
/*     b = xtod(in[5])*16+xtod(in[6]); */
/*     t = xtod(in[7])*16+xtod(in[8]); */
}

void set_tag_properties(GtkTextTag* tag, VALUE rbh_tm_settings) {
  VALUE rb_fg, rb_bg, rb_style;
  char fg[10], bg[10];
  rb_fg = rb_hash_aref(rbh_tm_settings, rb_str_new2("foreground"));
  if (rb_fg != Qnil) {
    clean_colour(RSTRING_PTR(rb_fg), fg);
    g_object_set(G_OBJECT(tag), "foreground", fg, NULL);
  }

  rb_bg = rb_hash_aref(rbh_tm_settings, rb_str_new2("background"));
  if (rb_bg != Qnil) {
    clean_colour(RSTRING_PTR(rb_bg), bg);
    g_object_set(G_OBJECT(tag), "background", bg, NULL);
  }

  rb_style = rb_hash_aref(rbh_tm_settings, rb_str_new2("fontStyle"));

  if (strstr(RSTRING_PTR(rb_style), "italic"))
    g_object_set(G_OBJECT(tag), "style", PANGO_STYLE_ITALIC, NULL);
  if (strstr(RSTRING_PTR(rb_style), "underline"))
    g_object_set(G_OBJECT(tag), "underline", PANGO_UNDERLINE_SINGLE, NULL);
  if (strstr(RSTRING_PTR(rb_style), "bold"))
    g_object_set(G_OBJECT(tag), "weight", PANGO_WEIGHT_BOLD, NULL);
    
  return;
}

void print_iter(GtkTextIter* iter) {
  printf("<%d,%d>",
	 gtk_text_iter_get_line(iter),
	 gtk_text_iter_get_line_offset(iter));
  return;
}

void colour_scope(GtkTextBuffer* buffer, Scope* scope, VALUE theme, int inner) {
  ScopeData* sd = scope->data;
  GtkTextIter start_iter, end_iter;
  VALUE rba_settings, rbh_setting, rb_settings, rb_settings_scope, rbh_tag_settings, rbh, rba_tag_settings, rba;
  char tag_name[256] = "nil";
  int priority = FIX2INT(rb_iv_get(sd->rb_scope, "@priority"));
  GtkTextTag* tag;
  GtkTextTagTable* tag_table;
  int i;

  scope_get_start_iter(scope, buffer, &start_iter, inner);
  scope_get_end_iter(scope, buffer, &end_iter, inner);

  rbh = rb_funcall(theme, rb_intern("global_settings"), 0);

  // set name
  rba_settings = rb_funcall(theme, rb_intern("settings_for_scope"), 2, sd->rb_scope, (inner ? Qtrue : Qnil));
  if (RARRAY(rba_settings)->len == 0) {
    snprintf(tag_name, 250, "default (%d)", priority);
  }
  else {
    rbh_setting = rb_ary_entry(rba_settings, 0);
    rb_settings = rb_hash_aref(rbh_setting, rb_str_new2("settings"));
    rb_settings_scope = rb_hash_aref(rbh_setting, rb_str_new2("scope"));
    snprintf(tag_name, 250, "%s (%d)", RSTRING(rb_settings_scope)->ptr, priority);
    rbh_tag_settings = rb_funcall(theme, rb_intern("textmate_settings_to_pango_options"), 1, rb_settings);
  }

  // lookup or create tag
  tag_table = gtk_text_buffer_get_tag_table(buffer);
  tag = gtk_text_tag_table_lookup(tag_table, tag_name);
  if (tag == NULL)
    tag = gtk_text_buffer_create_tag(buffer, tag_name, NULL);

  // set tag properties
  gtk_text_tag_set_priority(tag, priority-1);
  if (RARRAY(rba_settings)->len == 0)
    g_object_set(G_OBJECT(tag), "foreground", RSTRING(rb_hash_aref(rbh, rb_str_new2("foreground")))->ptr, NULL);
  else
    set_tag_properties(tag, rb_settings);

  printf("colouring scope: %s [%s] ", sd->name, tag_name);
  print_iter(&start_iter);
  printf("-"); 
  print_iter(&end_iter);
  puts("");
  gtk_text_buffer_apply_tag(buffer, tag, &start_iter, &end_iter);
  return;
}

static VALUE rb_colour_line_with_scopes(VALUE self, VALUE rb_colourer, VALUE theme,
				     VALUE rb_line_num, VALUE scopes) {
  printf("%d in line.\n", RARRAY(scopes)->len);
  int line_num = FIX2INT(rb_line_num);
  VALUE rb_buffer;
  GtkTextBuffer* buffer;
  GtkTextIter start_iter, end_iter;

  // remove all tags from line
  rb_buffer = rb_funcall(rb_iv_get(rb_colourer, "@sourceview"), rb_intern("buffer"), 0);
  
  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);
  gtk_text_buffer_get_iter_at_line_offset(buffer, &start_iter, line_num, 0);
  gtk_text_buffer_get_iter_at_line_offset(buffer, &end_iter, line_num+1, 0);
  gtk_text_buffer_remove_all_tags(buffer, &start_iter, &end_iter);

  // colour each scope
  int i;
  VALUE rb_current, pattern, content_name;
  Scope* current;
  ScopeData* current_data;
  for (i = 0; i < RARRAY(scopes)->len; i++) {
    rb_current = rb_ary_entry(scopes, i);
    Data_Get_Struct(rb_current, Scope, current);
    current_data = current->data;
    if (TEXTLOC_EQUAL(current_data->start, current_data->end))
      continue;
    pattern = rb_iv_get(rb_current, "@pattern");
    content_name = Qnil;
    if (pattern != Qnil)
      content_name = rb_iv_get(pattern, "@content_name");
    if (current_data->name == NULL && pattern != Qnil && 
	content_name == Qnil)
      continue;
    colour_scope(buffer, current, theme, FALSE);
  }
  
  return Qnil;
}

static VALUE mSyntaxExt, rb_mRedcar, rb_mSyntax;
static VALUE cScope;

void Init_syntax_ext() {
  // utility functions are in SyntaxExt
  mSyntaxExt = rb_define_module("SyntaxExt");
  rb_define_module_function(mSyntaxExt, "set_window_title", set_window_title, 2);
  rb_define_module_function(mSyntaxExt, "colour_line_with_scopes", 
		rb_colour_line_with_scopes, 4);

  rb_mRedcar = rb_define_module ("Redcar");
  rb_mSyntax = rb_define_module_under (rb_mRedcar, "Syntax");

  // the CScope class
  cScope = rb_define_class_under(rb_mSyntax, "Scope", rb_cObject);
  rb_define_alloc_func(cScope, rb_scope_alloc);
  rb_define_method(cScope, "initialize", rb_scope_init, 1);
  rb_define_method(cScope, "display",   rb_scope_print, 1);

  rb_define_method(cScope, "set_start", rb_scope_set_start, 2);
  rb_define_method(cScope, "set_end",   rb_scope_set_end, 2);  
  rb_define_method(cScope, "get_start", rb_scope_get_start, 0);
  rb_define_method(cScope, "get_end",   rb_scope_get_end, 0);

  rb_define_method(cScope, "set_open_end",    rb_scope_set_open_end, 2);
  rb_define_method(cScope, "set_close_start", rb_scope_set_close_start, 2);  
  rb_define_method(cScope, "get_open_end",    rb_scope_get_open_end, 0);
  rb_define_method(cScope, "get_close_start", rb_scope_get_close_start, 0);

  rb_define_method(cScope, "set_name",  rb_scope_set_name, 1);
  rb_define_method(cScope, "get_name",  rb_scope_get_name, 0);
  rb_define_method(cScope, "overlaps?", rb_scope_overlaps, 1);
  rb_define_method(cScope, "on_line?",  rb_scope_active_on_line, 1);

  rb_define_method(cScope, "add_child",  rb_scope_add_child, 1);
  rb_define_method(cScope, "delete_child",  rb_scope_delete_child, 1);
  rb_define_method(cScope, "get_children",  rb_scope_get_children, 0);
  rb_define_method(cScope, "get_parent",  rb_scope_get_parent, 0);
  rb_define_method(cScope, "clear_after",  rb_scope_clear_after, 1);
  rb_define_method(cScope, "clear_between",  rb_scope_clear_between, 2);
  rb_define_method(cScope, "clear_between_lines",  rb_scope_clear_between_lines, 2);
  rb_define_method(cScope, "n_children",  rb_scope_n_children, 0);
  rb_define_method(cScope, "detach",  rb_scope_detach, 0);
  rb_define_method(cScope, "delete_any_on_line_not_in",  
		rb_scope_delete_any_on_line_not_in, 2);
  rb_define_method(cScope, "clear_not_on_line",  rb_scope_clear_not_on_line, 1);
}
