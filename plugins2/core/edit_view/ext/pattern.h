
#include <oniguruma.h>

typedef struct SinglePattern_ {
  char* name;
	regex_t* match;
} SinglePattern;

typedef struct DoublePattern_ {
  char* name;
	regex_t* match;
} DoublePattern;
