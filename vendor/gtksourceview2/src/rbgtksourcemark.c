/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourcemark.c -

  $Author $
  $Date: 2004/08/05 18:13:49 $

  Copyright (C) 2003 Geoff Youngs, based on gtktextview.c by Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Class: Gtk::SourceMark
 * A source mark.
 */

#define _SELF(self) (GTK_SOURCE_MARK(RVAL2GOBJ(self)))

/* Class method: new(name, category)
 * name: mark name (string)
 * category: marker category (string)
 * 
 * Returns: a newly created Gtk::SourceMark object.
 */
static VALUE
sourcemark_new (self, name, category)
	VALUE self, name, category;
{
	G_INITIALIZE (self, 
		      gtk_source_mark_new (RVAL2CSTR(name), RVAL2CSTR(category)));
	return Qnil;
}

/* Method: category
 * Returns: the category of this mark.
 */
static VALUE
sourcemark_get_category (self)
	VALUE self;
{
	return CSTR2RVAL (gtk_source_mark_get_category (_SELF (self)));
}

/* Method: next(category)
 * category: the category id (string)
 * 
 * Returns: the next Gtk::SourceMark after the mark.
 */
static VALUE
sourcemark_next (self, category)
	VALUE self, category;
{
	return GOBJ2RVAL (gtk_source_mark_next (_SELF (self), RVAL2CSTR(category)));
}

/* Method: prev(category)
 * category: the category (string)
 *
 * Returns: the previous Gtk::SourceMark before the mark.
 */
static VALUE
sourcemark_prev (self, category)
	VALUE self, category;
{
	return GOBJ2RVAL (gtk_source_mark_prev (_SELF (self), RVAL2CSTR(category)));
}

void
Init_gtk_sourcemark ()
{
	VALUE csm = G_DEF_CLASS (GTK_TYPE_SOURCE_MARK, "SourceMark", mGtk);

	rb_define_method (csm, "initialize", sourcemark_new, 2);
	rb_define_method (csm, "category", sourcemark_get_category, 0);
	rb_define_method (csm, "next", sourcemark_next, 1);
	rb_define_method (csm, "prev", sourcemark_prev, 1);

	G_DEF_SETTERS (csm);
}
