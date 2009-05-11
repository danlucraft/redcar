/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourceiter.c -

  $Author: mutoh $
  $Date: 2005/01/03 15:33:56 $

  Copyright (C) 2004 Ruby-GNOME2 Project Team
************************************************/
#include "rbgtksourcemain.h"

#define _SELF(s) ((GtkTextIter*)RVAL2BOXED(s, GTK_TYPE_TEXT_ITER))
#define ITR2RVAL(i) (BOXED2RVAL(i, GTK_TYPE_TEXT_ITER))

/* FIXME: write documentation */

static VALUE
forward_search (argc, argv, self)
	int argc;
	VALUE *argv;
	VALUE self;
{
	GtkTextIter m_start, m_end;
	VALUE str, flags, limit;
	VALUE ret = Qnil;

	rb_scan_args (argc, argv, "21", &str, &flags, &limit);

	if (rb_obj_is_kind_of
	    (flags, GTYPE2CLASS (GTK_TYPE_SOURCE_SEARCH_FLAGS))) {
		if (gtk_source_iter_forward_search
		    (_SELF (self), RVAL2CSTR (str),
		     RVAL2GFLAGS (flags, GTK_TYPE_SOURCE_SEARCH_FLAGS),
		     &m_start, &m_end, NIL_P (limit) ? NULL : _SELF (limit)))
			ret =
			    rb_ary_new3 (2, ITR2RVAL (&m_start),
					 ITR2RVAL (&m_end));
	} else
	    if (rb_obj_is_kind_of
		(flags, GTYPE2CLASS (GTK_TYPE_TEXT_SEARCH_FLAGS))) {
		if (gtk_text_iter_forward_search
		    (_SELF (self), RVAL2CSTR (str),
		     RVAL2GFLAGS (flags, GTK_TYPE_TEXT_SEARCH_FLAGS), &m_start,
		     &m_end, NIL_P (limit) ? NULL : _SELF (limit)))
			ret =
			    rb_ary_new3 (2, ITR2RVAL (&m_start),
					 ITR2RVAL (&m_end));
	}
	return ret;
}

static VALUE
backward_search (argc, argv, self)
	int argc;
	VALUE *argv;
	VALUE self;
{
	GtkTextIter m_start, m_end;
	VALUE str, flags, limit;
	VALUE ret = Qnil;

	rb_scan_args (argc, argv, "21", &str, &flags, &limit);
	if (rb_obj_is_kind_of
	    (flags, GTYPE2CLASS (GTK_TYPE_SOURCE_SEARCH_FLAGS))) {
		if (gtk_source_iter_backward_search
		    (_SELF (self), RVAL2CSTR (str),
		     RVAL2GFLAGS (flags, GTK_TYPE_SOURCE_SEARCH_FLAGS),
		     &m_start, &m_end, NIL_P (limit) ? NULL : _SELF (limit)))
			ret =
			    rb_ary_new3 (2, ITR2RVAL (&m_start),
					 ITR2RVAL (&m_end));
	} else
	    if (rb_obj_is_kind_of
		(flags, GTYPE2CLASS (GTK_TYPE_TEXT_SEARCH_FLAGS))) {
		if (gtk_text_iter_backward_search
		    (_SELF (self), RVAL2CSTR (str),
		     RVAL2GFLAGS (flags, GTK_TYPE_TEXT_SEARCH_FLAGS), &m_start,
		     &m_end, NIL_P (limit) ? NULL : _SELF (limit)))
			ret =
			    rb_ary_new3 (2, ITR2RVAL (&m_start),
					 ITR2RVAL (&m_end));
	}
	return ret;
}

void
Init_gtk_sourceiter ()
{
	VALUE cTextIter = GTYPE2CLASS (GTK_TYPE_TEXT_ITER);

	/*
	 * They are override original Gtk::TextIter#[for|back]ward_search 
	 */
	rb_define_method (cTextIter, "forward_search", forward_search, -1);
	rb_define_method (cTextIter, "backward_search", backward_search, -1);

        G_DEF_CLASS(GTK_TYPE_SOURCE_SEARCH_FLAGS, "SourceSearchFlags", cTextIter);
        G_DEF_CONSTANTS(cTextIter, GTK_TYPE_SOURCE_SEARCH_FLAGS, "GTK_");
}
