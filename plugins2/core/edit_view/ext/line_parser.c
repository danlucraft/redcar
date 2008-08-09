
#include "ruby.h"
#include "textloc.h"
#include "scope.h"
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

// -------- Colouring stuff

int minify(int offset) {
  return (offset < 200 ? offset : 200);
}

int char_to_hex(int ch) {
  if (ch >= 48 && ch <= 57)
    return ch-48;
	if (ch >= 65 && ch <= 70)
		return ch-55;
	if (ch >= 97 && ch <= 102)
		return ch-87;
  return 0;
}

// Here parent_colour is like '#FFFFFF' and
// colour is like '#000000DD'.
char* merge_colour(char* parent_colour, char* colour) {
  int pre_r, pre_g, pre_b;
  int post_r, post_g, post_b;
  int opacity;
  int new_r, new_g, new_b;
  char* new_colour = NULL;
  if (parent_colour == NULL)
    return NULL;
  if (strlen(colour) == 7)
    return colour;
  if (strlen(colour) == 9) {
    pre_r = char_to_hex(parent_colour[1])*16+char_to_hex(parent_colour[2]);
    pre_g = char_to_hex(parent_colour[3])*16+char_to_hex(parent_colour[4]);
    pre_b = char_to_hex(parent_colour[5])*16+char_to_hex(parent_colour[6]);

    post_r = char_to_hex(colour[1])*16+char_to_hex(colour[2]);
    post_g = char_to_hex(colour[3])*16+char_to_hex(colour[4]);
    post_b = char_to_hex(colour[5])*16+char_to_hex(colour[6]);
    opacity = char_to_hex(colour[7])*16+char_to_hex(colour[8]);

    new_r = (pre_r*(255-opacity) + post_r*opacity)/255;
    new_g = (pre_g*(255-opacity) + post_g*opacity)/255;
    new_b = (pre_b*(255-opacity) + post_b*opacity)/255;
    new_colour = malloc(7); // FIXME: memory leak
    sprintf(new_colour, "#%.2x%.2x%.2x", new_r, new_g, new_b);
/* 		printf("%s/%s/%s - %d,%d,%d\n", parent_colour, colour, new_colour, new_r, new_g, new_b); */
    return new_colour;
  }
  return "#000000";
}

#define xtod(c) ((c>='0' && c<='9') ? c-'0' : ((c>='A' && c<='F') ? c-'A'+10 : ((c>='a' && c<='f') ? c-'a'+10 : 0)))

void set_tag_properties(Scope* scope, GtkTextTag* tag, VALUE rbh_tm_settings) {
  ScopeData* sd = scope->data;
  VALUE rb_fg, rb_bg, rb_style, rb_parent_bg;
  char fg[10], bg[10];
  char* parent_bg = NULL;
  char* merged_colour = NULL;
  VALUE rb_cTheme = rb_eval_string("Redcar::EditView::Theme");
  rb_fg = rb_hash_aref(rbh_tm_settings, rb_str_new2("foreground"));
  if (rb_fg != Qnil) {
    g_object_set(G_OBJECT(tag), "foreground", RSTRING_PTR(rb_fg), NULL);
  }
  rb_bg = rb_hash_aref(rbh_tm_settings, rb_str_new2("background"));
  if (rb_bg != Qnil) {
    parent_bg = scope_nearest_bg_color(scope);
    merged_colour = merge_colour(parent_bg, RSTRING_PTR(rb_bg));
    g_object_set(G_OBJECT(tag), "background", merged_colour, NULL);
    sd->bg_color = merged_colour;
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
  int priority = scope_get_priority(scope);
  GtkTextTag* tag = NULL;
  GtkTextTagTable* tag_table;
  int i;
  char *get_tag_name;

  sd->coloured = 1;
  if (inner) {
    gtk_text_buffer_get_iter_at_mark(buffer, &start_iter, sd->inner_start_mark);
    gtk_text_buffer_get_iter_at_mark(buffer, &end_iter, sd->inner_end_mark);
    if (sd->inner_tag != NULL)
      tag = sd->inner_tag;
  }
  else {
    gtk_text_buffer_get_iter_at_mark(buffer, &start_iter, sd->start_mark);
    gtk_text_buffer_get_iter_at_mark(buffer, &end_iter, sd->end_mark);
    if (sd->tag != NULL)
      tag = sd->tag;
  }
  
  if (tag == NULL) {
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
  buffer = (GtkTextBuffer *) get_gobject(rb_buffer);

  // colour each scope
  int i;
  VALUE rb_current, pattern, content_name;
  Scope* current;
  ScopeData* current_data;
  for (i = 0; i < RARRAY(scopes)->len; i++) {
    rb_current = rb_ary_entry(scopes, i);
    Data_Get_Struct(rb_current, Scope, current);
    if (G_NODE_IS_ROOT(current))
      continue;
    current_data = current->data;
    pattern = rb_iv_get(rb_current, "@pattern");
    content_name = Qnil;
    if (pattern != Qnil)
      content_name = rb_iv_get(pattern, "@content_name");
    if (current_data->name == NULL && pattern != Qnil && 
        content_name == Qnil)
      continue;
    if (current_data->coloured)
      continue;
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
  sd->coloured = 0;
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
/*     delete_marks(buffer, current); */
  }
  return Qnil;
}

/// LineParser

typedef struct LineParser_ {
  VALUE  line;
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
  lp->line        = line;
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
  rb_md = rb_funcall(rb_closing_regexp, rb_intern("match"), 2, lp->line, INT2FIX(thispos));
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
    rb_md        = rb_funcall(rb_match_re, rb_intern("match"), 2, lp->line, INT2FIX(lp->pos));
    if (rb_md != Qnil) {
      rb_from = rb_funcall(rb_md, rb_intern("begin"), 1, INT2FIX(0));
      rb_scope_marker = rb_hash_new();
      from = NUM2INT(rb_hash_aset(rb_scope_marker, ID2SYM(rb_intern("from")), rb_from));
      line_parser_update_scope_marker(lp, from, rb_pattern, rb_md);
      return rb_scope_marker;
    }
  }
	regex_t * reg;
	int r;
	OnigErrorInfo einfo;
	UChar* pat_ptr = (UChar* ) RSTRING_PTR(rb_funcall(rb_match_re, rb_intern("source"), 0));
	int pat_len = strlen(pat_ptr);
	int iOptions = 256;
	OnigEncodingType * iEncoding = ONIG_ENCODING_UTF8;
	OnigSyntaxType * iSyntax = ONIG_SYNTAX_DEFAULT;
	r = onig_new(&reg, pat_ptr, pat_ptr + pat_len, iOptions, iEncoding, iSyntax, &einfo);
	if (r != ONIG_NORMAL) {
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r, &einfo);
		rb_raise(rb_eArgError, "Oniguruma Error: %s", s);
	}

	UChar* str_ptr = (UChar* ) lp->line;
	int str_len = strlen(str_ptr);
	
	int begin = lp->pos;
	int end = str_len;
	OnigRegion *region = onig_region_new();
  r = onig_search(reg, str_ptr, str_ptr + str_len, str_ptr + begin, str_ptr + end, region, ONIG_OPTION_NONE);
	if (r >= 0) {
    int i , count = region->num_regs;

    for ( i = 0; i < count; i++){
    }

		onig_region_free(region, 1 );
	} else if (r == ONIG_MISMATCH) {
		onig_region_free(region, 1 );
	} else {
		onig_region_free(region, 1 );
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r);
		rb_raise(rb_eArgError, "Oniguruma Error: %s", s);
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

/* def get_expected_scope */
/*   expected_scope = current_scope.first_child_after(TextLoc.new(line_num, pos), starting_child) */
/*   return nil if expected_scope == current_scope */
/*   if expected_scope */
/*     expected_scope = nil unless expected_scope.start.line == line_num */
/*   end */
/*   while expected_scope and expected_scope.capture */
/*     expected_scope = expected_scope.parent */
/*   end */
/*   expected_scope */
/* end */

Scope* line_parser_get_expected_scope(LineParser* lp) {
	TextLoc loc;
	Scope *expected_scope = NULL;
	ScopeData *sd;
	loc.line   = lp->line_num;
	loc.offset = lp->pos;
	expected_scope = scope_first_child_after(lp->current_scope, &loc, lp->starting_child);
	if (expected_scope == lp->current_scope)
		return NULL;
	if (expected_scope != NULL) {
		sd = expected_scope->data;
		scope_start_loc(expected_scope, &loc);
		if (loc.line != lp->line_num)
			expected_scope = NULL;
		while (expected_scope != NULL && sd->is_capture == 1) {
			expected_scope = expected_scope->parent;
			sd = expected_scope->data;
		}
	}
	if (expected_scope == NULL)
		return NULL;
	return expected_scope;
}

static VALUE rb_line_parser_get_expected_scope(VALUE self) {
  LineParser *lp;
  Data_Get_Struct(self, LineParser, lp);
	Scope* es = line_parser_get_expected_scope(lp);
	ScopeData* sd;
	if (es == NULL)
		return Qnil;
	else {
		sd = es->data;
		return sd->rb_scope;
	}
}

static VALUE mSyntaxExt, rb_mRedcar, rb_cEditView, rb_cParser;
static VALUE cScope, cTextLoc, cLineParser;

void Init_line_parser() {
  // utility functions are in SyntaxExt
  mSyntaxExt = rb_define_module("SyntaxExt");
  rb_define_module_function(mSyntaxExt, "colour_line_with_scopes", 
                            rb_colour_line_with_scopes, 3);
  rb_define_module_function(mSyntaxExt, "uncolour_scopes", 
                            rb_uncolour_scopes, 2);

  rb_mRedcar = rb_define_module ("Redcar");
  rb_cEditView = rb_eval_string("Redcar::EditView");
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
  rb_define_method(cLineParser, "get_expected_scope", rb_line_parser_get_expected_scope, 0);

	printf("onig_test...\n");
	regex_t * reg;
	int r;
	OnigErrorInfo einfo;
	UChar* pat_ptr = (UChar* ) "(f(oo))(\\s+)(bar)";
	int pat_len = strlen(pat_ptr);
	int iOptions = 0;
	OnigEncodingType * iEncoding = ONIG_ENCODING_UTF8;
	OnigSyntaxType * iSyntax = ONIG_SYNTAX_DEFAULT;
	r = onig_new(&reg, pat_ptr, pat_ptr + pat_len, iOptions, iEncoding, iSyntax, &einfo);
	if (r != ONIG_NORMAL) {
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r, &einfo);
		rb_raise(rb_eArgError, "Oniguruma Error: %s", s);
	}

	UChar* str_ptr = (UChar* ) "foo  bar";
	int str_len = strlen(str_ptr);
	
	int begin = 0;
	int end = str_len;
	OnigRegion *region = onig_region_new();
	printf("match: %s against %s\n", pat_ptr, str_ptr);
  r = onig_search(reg, str_ptr, str_ptr + str_len, str_ptr + begin, str_ptr + end, region, ONIG_OPTION_NONE);
	if (r >= 0) {
		printf("match.\n");
    int i , count = region->num_regs;

    for ( i = 0; i < count; i++){
			printf("region: %d - %d\n", region->beg[i], region->end[i]);
    }

		onig_region_free(region, 1 );
	} else if (r == ONIG_MISMATCH) {
		printf("mismatch %d.\n", r);
		onig_region_free(region, 1 );
	} else {
		printf("error.\n");
		onig_region_free(region, 1 );
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r);
		rb_raise(rb_eArgError, "Oniguruma Error: %s", s);
	}
}

