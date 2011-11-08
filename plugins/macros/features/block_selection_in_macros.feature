Feature: Block selection in macros
 The macros should behave correctly around block selection mode.

 Background:
   When I open a new edit tab
   Given the content is:
       """
       foo
       bar
       baz
       """
   And I move to the start of the text
   
 Scenario: Set the correct block selection mode before running the macro
   When I turn block selection on
   And I start recording a macro
   And I select down
   And I select down
   And I type "a"
   And I stop recording a macro
   And I turn block selection off
   And I move to the start of the text
   And I run the last recorded macro
   Then the content should be:
       """
       aafoo
       aabar
       aabaz
       """
       
 Scenario: Change block selection mode during the macro
   And I start recording a macro
   When I turn block selection on
   And I select down
   And I select down
   And I type "a"
   And I stop recording a macro
   And I turn block selection off
   And I move to the start of the text
   And I run the last recorded macro
   Then the content should be:
       """
       aafoo
       aabar
       aabaz
       """

    