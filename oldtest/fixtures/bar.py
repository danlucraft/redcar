# -*- coding: utf-8 -*-
# Copyright © 2005 Lateef Alabi-Oki
#
#
# (at your option) any later version.

"""
This modules exposes a class that creates the text editor's bar object.
@author: Lateef Alabi-Oki
"""

from gtk import Table

class ScribesBar(Table):
	"""
	This class creates the text editor's bar object. The bar object is a
	widgets.
	"""

	def __init__(self, editor):
		"""
		Initialize the bar object.
		@type editor: An Editor object.
		"""
		Table.__init__(self)
		self.__init_attributes(editor)
		self.__set_properties()
		self.connect("key-press-event", self.__key_press_event_cb)

	def __set_properties(self):
		"""
		Define the property of the bar object.
		@type self: A ScribesBar object.
		"""
		self.set_property("receives-default", True)
		return
