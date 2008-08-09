
#include "textloc.h"
#include "scope.h"
#include "line_parser.h"
#include "pattern.h"
#include "theme.h"
#include <ruby.h>

void Init_redcar_ext() {
  Init_scope();
  Init_line_parser();
  Init_pattern();
  Init_textloc();
  Init_theme();
}
