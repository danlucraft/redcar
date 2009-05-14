/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourceview.c -

  $Author: mutoh $
  $Date: 2006/12/17 16:15:28 $

  Copyright (C) 2004,2005 Ruby-GNOME2 Project Team
  Copyright (C) 2003 Geoff Youngs, based on gtktextview.c by Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Class: Gtk::SourceView
 * A view on a source.
 */
#define _SELF(self) (GTK_SOURCE_VIEW(RVAL2GOBJ(self)))

/*
 * Class method: new(buffer=nil)
 * buffer: a Gtk::SourceBuffer object.
 *
 * Creates a new Gtk::SourceView.  If buffer is not provided or nil, an empty
 * buffer will be created for you.  Note that one buffer can be shared among
 * many widgets.
 * 
 * Returns: a newly created Gtk::SourceView object.
 */
static VALUE
sourceview_initialize (argc, argv, self)
	int argc;
	VALUE *argv;
	VALUE self;
{
	VALUE buffer;
	GtkWidget *widget;

	rb_scan_args (argc, argv, "01", &buffer);

	if (NIL_P (buffer))
		widget = gtk_source_view_new ();
	else
		widget = gtk_source_view_new_with_buffer (RVAL2GOBJ (buffer));

	RBGTK_INITIALIZE (self, widget);
	return self;
}

/* Defined as properties.
void        gtk_source_view_set_show_line_numbers
                                            (GtkSourceView *view,
                                             gboolean show);
gboolean    gtk_source_view_get_show_line_numbers
                                            (GtkSourceView *view);
void        gtk_source_view_set_show_line_marks
                                            (GtkSourceView *view,
                                             gboolean show);
gboolean    gtk_source_view_get_show_line_marks
                                            (GtkSourceView *view);
void        gtk_source_view_set_tabs_width  (GtkSourceView *view,
                                             guint width);
guint       gtk_source_view_get_tabs_width  (GtkSourceView *view);
void        gtk_source_view_set_auto_indent (GtkSourceView *view,
                                             gboolean enable);
gboolean    gtk_source_view_get_auto_indent (GtkSourceView *view);
void        gtk_source_view_set_insert_spaces_instead_of_tabs
                                            (GtkSourceView *view,
                                             gboolean enable);
gboolean    gtk_source_view_get_insert_spaces_instead_of_tabs
                                            (GtkSourceView *view);
Since 1.8
void        gtk_source_view_set_indent_on_tab
                                            (GtkSourceView *view,
                                             gboolean enable);
Since 1.8
gboolean    gtk_source_view_get_indent_on_tab
                                            (GtkSourceView *view);
void        gtk_source_view_set_show_margin (GtkSourceView *view,
                                             gboolean show);
gboolean    gtk_source_view_get_show_margin (GtkSourceView *view);
void        gtk_source_view_set_margin      (GtkSourceView *view,
                                             guint margin);
guint       gtk_source_view_get_margin      (GtkSourceView *view);
*/

/*
 * Method: set_mark_category_pixbuf(marker_type, pixbuf)
 * marker_type: a marker type (as a string).
 * pixbuf: a Gdk::Pixbuf object.
 *
 * Associates a given pixbuf with a given marker_type.
 *
 * Returns: self.
 */
static VALUE
sourceview_set_mark_category_pixbuf (self, marker_type, pixbuf)
	VALUE self, marker_type, pixbuf;
{
	gtk_source_view_set_mark_category_pixbuf (_SELF (self),
					   RVAL2CSTR (marker_type),
					   GDK_PIXBUF (RVAL2GOBJ (pixbuf)));
	return self;
}

/*
 * Method: get_marker_type(marker_type)
 * marker_type: a marker type (as a string).
 *
 * Gets the pixbuf which is associated with the given marker_type. 
 *
 * Returns: a Gdk::Pixbuf object if found, or nil if not found.
 */
static VALUE
sourceview_get_mark_category_pixbuf (self, marker_type)
	VALUE self, marker_type;
{
	return
	    GOBJ2RVAL (gtk_source_view_get_mark_category_pixbuf
		       (_SELF (self), RVAL2CSTR (marker_type)));
}

void
Init_gtk_sourceview ()
{
    VALUE cSourceView = G_DEF_CLASS (GTK_TYPE_SOURCE_VIEW, "SourceView", mGtk);

    rb_define_const(cSourceView, "BUILD_VERSION",
                    rb_ary_new3(3,
                                INT2FIX(GTKSOURCEVIEW2_MAJOR_VERSION),
                                INT2FIX(GTKSOURCEVIEW2_MINOR_VERSION),
                                INT2FIX(GTKSOURCEVIEW2_MICRO_VERSION)));
    
    rb_define_method(cSourceView, "get_mark_category_pixbuf", sourceview_get_mark_category_pixbuf, 1);
    rb_define_method(cSourceView, "set_mark_category_pixbuf", sourceview_set_mark_category_pixbuf, 2);
    rb_define_method(cSourceView, "initialize", sourceview_initialize, -1);
    
    G_DEF_SETTERS (cSourceView);
}
