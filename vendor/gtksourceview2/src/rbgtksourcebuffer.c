/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/************************************************

  rbgtksourcebuffer.c -

  $Author: sakai $
  $Date: 2007/07/08 03:02:28 $

  Copyright (C) 2004,2005 Ruby-GNOME2 Project Team
  Copyright (C) 2003 Geoff Youngs, based on gtktextview.c by Masao Mutoh
************************************************/
#include "rbgtksourcemain.h"

/* Class: Gtk::SourceBuffer
 * Text buffer object for Gtk::SourceView.
 */

#define _SELF(self) (GTK_SOURCE_BUFFER(RVAL2GOBJ(self)))
#define RVAL2ITR(i) ((GtkTextIter*)RVAL2BOXED(i, GTK_TYPE_TEXT_ITER))
#define RVAL2MARKER(m) (GTK_SOURCE_MARKER(RVAL2GOBJ(marker)))

/*
 * Class method: new(obj=nil)
 * obj: either a Gtk::TextTagTable, a Gtk::SourceLanguage, or nil. 
 *
 * Creates a new source buffer.  If a Gtk::SourceTagTable is provided, the
 * buffer will use it, otherwise it will create a new one.
 *
 * If a Gtk::SourceLanguage object is given, the buffer will be created
 * using highlightings patterns in this language. This is equivalent to
 * creating a new source buffer with the default tag table and then setting
 * the 'language' property.
 * 
 * Returns: a newly created Gtk::SourceBuffer object.
 */
static VALUE
sourcebuffer_new (argc, argv, self)
	int argc;
	VALUE *argv;
	VALUE self;
{
	VALUE val;

	rb_scan_args (argc, argv, "01", &val);
	if (NIL_P (val)) {
		G_INITIALIZE (self, gtk_source_buffer_new (NULL));
	} else
	    if (rb_obj_is_kind_of
		(val, GTYPE2CLASS (GTK_TYPE_TEXT_TAG_TABLE))) {
		G_INITIALIZE (self,
			      gtk_source_buffer_new (GTK_TEXT_TAG_TABLE
						     (RVAL2GOBJ (val))));
	} else
	    if (rb_obj_is_kind_of
		(val, GTYPE2CLASS (GTK_TYPE_SOURCE_LANGUAGE))) {
		G_INITIALIZE (self,
			      gtk_source_buffer_new_with_language
			      (GTK_SOURCE_LANGUAGE (RVAL2GOBJ (val))));
	} else {
		rb_raise (rb_eArgError,
			  "invalid argument %s (expect nil, Gtk::TextTagTable or Gtk::SourceLanguage)",
			  rb_class2name (CLASS_OF (val)));
	}
	return Qnil;
}

/*
 * Method: can_redo?
 *
 * Determines whether a source buffer can redo the last action (i.e. if the
 * last operation was an undo).
 *
 * Returns: whether a redo is possible.
 */
static VALUE
sourcebuffer_can_redo (self)
	VALUE self;
{
	return CBOOL2RVAL (gtk_source_buffer_can_redo (_SELF (self)));
}

/*
 * Method: can_undo?
 *
 * Determines whether a source buffer can undo the last action.
 *
 * Returns: whether it's possible to undo the last action. 
 */
static VALUE
sourcebuffer_can_undo (self)
	VALUE self;
{
	return CBOOL2RVAL (gtk_source_buffer_can_undo (_SELF (self)));
}

/*
 * Method: redo!
 *
 * Redoes the last undo operation. Use Gtk::SourceBuffer#can_redo? to check
 * whether a call to this function will have any effect.
 *
 * Returns: self.
 */
static VALUE
sourcebuffer_redo (self)
	VALUE self;
{
	gtk_source_buffer_redo (_SELF (self));
	return self;
}

/*
 * Method: undo!
 *
 * Undoes the last user action which modified the buffer.
 * Use Gtk::SourceBuffer#can_undo? to check whether a call to this function
 * will have any effect.
 *
 * Actions are defined as groups of operations between a call to 
 * Gtk::TextBuffer#begin_user_action and Gtk::TextBuffer#end_user_action,
 * or sequences of similar edits (inserts or deletes) on the same line.
 *
 * Returns: self.
 */
static VALUE
sourcebuffer_undo (self)
	VALUE self;
{
	gtk_source_buffer_undo (_SELF (self));
	return self;
}

/*
 * Method: begin_not_undoable_action
 * Method: begin_not_undoable_action { ... }
 * 
 * Marks the beginning of a not undoable action on the buffer, disabling the
 * undo manager.
 * 
 * If a block is given, the block is called after marking the beginning
 * of a not undoable action on the buffer.
 * At the end of the block, marks the end of a not undoable action on the
 * buffer. When the last not undoable block is finished, the list of undo
 * actions is cleared and the undo manager is re-enabled.
 *
 * Returns: self
 */
static VALUE
sourcebuffer_begin_not_undoable_action(self)
    VALUE self;
{
    gtk_source_buffer_begin_not_undoable_action (_SELF (self));

    if (rb_block_given_p()) {
	VALUE block = rb_block_proc ();
	rb_funcall (block, rb_intern ("call"), 0);
	gtk_source_buffer_end_not_undoable_action (_SELF (self));
    }
    return self;
}

/*
 * Method: end_not_undoable_action
 * 
 * Marks the end of a not undoable action on the buffer.
 * When the last not undoable block is finished, the list of undo
 * actions is cleared and the undo manager is re-enabled.
 *
 * Returns: self
 */
static VALUE
sourcebuffer_end_not_undoable_action(self)
    VALUE self;
{
    gtk_source_buffer_end_not_undoable_action (_SELF (self));
    return self;
}


/*
 * Method: not_undoable_action { ... }
 * 
 * Marks the beginning of a not undoable action on the buffer, disabling the
 * undo manager, then calls the provided block of code.
 * 
 * At the end of the block, marks the end of a not undoable action on the
 * buffer. When the last not undoable block is finished, the list of undo
 * actions is cleared and the undo manager is re-enabled.
 *
 * ((*Deprecated*)). Use Gtk::SourceView#begin_not_undoable_action{ ... } instead.
 *
 * Returns: the return value of the provided block.
 */
static VALUE
sourcebuffer_not_undoable_action (self)
	VALUE self;
{
	VALUE block, ret;

	block = rb_block_proc ();
	gtk_source_buffer_begin_not_undoable_action (_SELF (self));
	ret = rb_funcall (block, rb_intern ("call"), 0);
	gtk_source_buffer_end_not_undoable_action (_SELF (self));
	return ret;
}

/*
 * Method: create_source_mark(name=nil, category, where)
 * name: the name of the marker.
 * type: a string defining the marker type. 
 * where: a location to place the marker, as a Gtk::TreeIter object. 
 *
 * Creates a marker in the buffer of the given type. A marker is semantically
 * very similar to a Gtk::TextMark, except it has a type which is used by the
 * Gtk::SourceView object displaying the buffer to show a pixmap on the left
 * margin, at the line the marker is in. Because of this, a marker is generally
 * associated to a line and not a character position. Markers are also
 * accessible through a position or range in the buffer.
 *
 * Markers are implemented using Gtk::TextMark, so all characteristics and
 * restrictions to marks apply to markers too. These includes life cycle issues
 * and "mark-set" and "mark-deleted" signal emissions.
 *
 * Like a Gtk::TextMark, a Gtk::SourceMarker can be anonymous if the passed
 * name is nil. 
 *
 * Markers always have left gravity and are moved to the beginning of the line
 * when the user deletes the line they were in. Also, if the user deletes a
 * region of text which contained lines with markers, those are deleted.
 *
 * Typical uses for a marker are bookmarks, breakpoints, current executing
 * instruction indication in a source file, etc..
 *
 * Returns: a new Gtk::SourceMark object, owned by the buffer.
 */
static VALUE
sourcebuffer_create_source_mark (argc, argv, self)
	int argc;
	VALUE *argv, self;
{
	VALUE name, category, where;

	if (argc == 2)
		rb_scan_args (argc, argv, "21", &where, &category, &name);
	else
		rb_scan_args (argc, argv, "30", &name, &category, &where);

	return GOBJ2RVAL (gtk_source_buffer_create_source_mark (_SELF (self),
							   RVAL2CSTR (name),
							   RVAL2CSTR (category),
							   RVAL2ITR (where)));
}

void
Init_gtk_sourcebuffer ()
{
	VALUE cbuffer =
	    G_DEF_CLASS (GTK_TYPE_SOURCE_BUFFER, "SourceBuffer", mGtk);

	rb_define_method (cbuffer, "initialize", sourcebuffer_new, -1);
	rb_define_method (cbuffer, "can_redo?", sourcebuffer_can_redo, 0);
	rb_define_method (cbuffer, "can_undo?", sourcebuffer_can_undo, 0);
	rb_define_method (cbuffer, "redo!", sourcebuffer_redo, 0);
	rb_define_method (cbuffer, "undo!", sourcebuffer_undo, 0);
	rb_define_method (cbuffer, "begin_not_undoable_action",
			  sourcebuffer_begin_not_undoable_action, 0);
	rb_define_method (cbuffer, "end_not_undoable_action",
			  sourcebuffer_end_not_undoable_action, 0);
	rb_define_method (cbuffer, "not_undoable_action",
			  sourcebuffer_not_undoable_action, 0);
	rb_define_alias (cbuffer, "non_undoable_action",
			 "not_undoable_action");
	rb_define_method (cbuffer, "create_source_mark", sourcebuffer_create_source_mark,
			  -1);

	G_DEF_SETTERS (cbuffer);
}
