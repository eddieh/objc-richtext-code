
/*
 * Copyright (C) 1998 David Stes.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published 
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <objc.h>
#include "style.h"
#include "richtext.h"
#include <ordcltn.h>
#include <ocstring.h>

/* defaults per Microsoft (RTF 1.3) spec */
#define LEFTINDENT 0
#define RIGHTINDENT 0
#define FIRSTINDENT 0
#define ALIGNMENT ALGNLEFT
#define SPACEBEFORE 0
#define SPACEAFTER 0
#define SPACELINE 0

@implementation Style 

+ new
{
  return [[super new] pardefaults];
}

- copy
{
  return [[super copy] tabs:[tabs deepCopy]];
}

- (BOOL)isEqual:b
{
  if (firstindent != [b firstindent]) return NO;
  if (rightindent != [b rightindent]) return NO;
  if (leftindent != [b leftindent]) return NO;
  if (alignment != [b alignment]) return NO;
  if (spacebefore != [b spacebefore]) return NO;
  if (spaceafter != [b spaceafter]) return NO;
  if (spaceline != [b spaceline]) return NO;
  if (tabs == nil && [b tabs] != nil) return NO;
  if (tabs != nil && [b tabs] == nil) return NO;
  if (tabs && ![tabs isEqual:[b tabs]]) return NO;
  return YES;
}

- pardefaults
{
  firstindent = FIRSTINDENT;
  rightindent = RIGHTINDENT;
  leftindent  = LEFTINDENT;
  if (tabs) tabs = [[tabs freeContents] free];
  alignment = ALIGNMENT;
  spacebefore = SPACEBEFORE;
  spaceafter = SPACEAFTER;
  spaceline = SPACELINE;
  return self;
}

- (int)firstindent
{
  return firstindent;
}

- setfirstindent:(int)num
{
  firstindent = num;return self;
}

- (int)leftindent
{
  return leftindent;
}

- setleftindent:(int)num
{
  leftindent = num;return self;
}

- (int)rightindent
{
  return rightindent;
}

- setrightindent:(int)num
{
  rightindent = num;return self;
}

- tabs
{
  return tabs;
}

- tabs:x
{
  tabs = x;
  return self;
}

- settab:(int)num
{
  if (!tabs) tabs = [OrdCltn new];
  [tabs add:[String sprintf:"%i",num]];
  return self;
}

- (int)alignment
{
  return alignment;
}

- setalign:(int)num
{
  alignment = num;return self;
}

- (int)spacebefore
{
  return spacebefore;
}

- setspacebefore:(int)num
{
  spacebefore = num;return self;
}

- (int)spaceafter
{
  return spaceafter;
}

- setspaceafter:(int)num
{
  spaceafter = num;return self;
}

- (int)spaceline
{
  return spaceline;
}

- setspaceline:(int)num
{
  spaceline = num;return self;
}

- writertf:(IOD)d
{
  int i,n;
  fprintf(d,"\\pard");
  if (leftindent != LEFTINDENT) fprintf(d,"\\li%d",leftindent);
  if (rightindent != RIGHTINDENT) fprintf(d,"\\ri%d",rightindent);
  if (firstindent != FIRSTINDENT) fprintf(d,"\\fi%d",firstindent);
  switch (alignment) {
    case ALIGNMENT : break;
    case ALGNRIGHT : fprintf(d,"\\qr");break;
    case ALGNJUST : fprintf(d,"\\qj");break;
    case ALGNCENTER : fprintf(d,"\\qc");break;
  }
  if (spacebefore != SPACEBEFORE) fprintf(d,"\\sb%d",spacebefore);
  if (spaceafter != SPACEAFTER) fprintf(d,"\\sa%d",spaceafter);
  if (spaceline != SPACELINE) fprintf(d,"\\sl%d",spaceline);
  n = (tabs)?[tabs size]:0;
  for(i=0;i<n;i++) fprintf(d,"\\tx%s",[[tabs at:i] str]);
  fprintf(d,"\n");
  return self;
}

- (int)nextTabfromx:(int)x leftmargin:(int)lm rightmargin:(int)rm
{
  if (tabs) {
    int i,n = [tabs size];
    for(i=0;i<n;i++) {
      int tx = twips2points([[tabs at:i] asInt]);
      if (x < tx) return tx;  
    }
    return rm; /* need newline */
  } else {
    return x + 100;
  }
}

@end

