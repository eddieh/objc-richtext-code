
/* small test program, just to catch syntax errors in afm files */

/* compile with : objc afmparse.m AFM.o afmlex.o */

#include <Object.h>
#include "AFM.h"

int main(int n,char **v)
{
  if (n) {
    int i;
    for(i=1;i<n;i++) {
      id x = [AFM open:v[i]];
    }
  } else {
    printf("Usage : %s file.afm ...\n");
    exit(1);
  }
}

