
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
#include <string.h>
#include <ocstring.h>
#include <octext.h>
#include <ordcltn.h>
#include <paragrph.h>
#include <txtattr.h>
#include "state.h"
#include "richfont.h"
#include "boldface.h"
#include "underlined.h"
#include "italic.h"
#include "fontchange.h"
#include "fontsizechange.h"
#include "richtext.h"
#include <assert.h>

@implementation State 

+ new
{
  return [[super new] chardefaults];
}

- richtext
{
  return richtext;
}

- richtext:x
{
  richtext = x;return self;
}

- pardefaults
{
  /* should not reset things like destination, boldface (char props) */
  /* in particular you can have e.g. {\footer\pard ... } */
  [[richtext laststyle] pardefaults];
  return self;
}

- chardefaults
{
  boldface = NO;
  underlined = NO;
  italic = NO;
  fontnum = [richtext defaultfont];
  fontsize = FONTSIZE;
  return self;
}

- newparagraph
{
  [self addchars:"\n" count:1];
  [richtext newparagraph];
  return self;
}

- setunderlined:(BOOL)flag
{
  underlined = flag;return self;
}

- setboldface:(BOOL)flag
{
  boldface = flag;return self;
}

- setitalic:(BOOL)flag
{
  italic = flag;return self;
}

- setfontnum:(int)num
{
  fontnum = num;return self;
}

- textStyle
{
  return [richtext laststyle];
}

- setforecolor:(int)num
{
  return self;
}

- setbackcolor:(int)num
{
  return self;
}

- setfontsize:(int)num
{
  fontsize = num;return self;
}

- setfontfamily:(int)num
{
  fontfamily = num;return self;
}

- setdestination:(int)num
{
  destination = num;return self;
}

- addch:(char)c
{
  return [self add:[String sprintf:"%c",c]];
}

- addfontnamed:(char *)p
{
  int n = strlen(p);
  if (n>=1 && p[n-1]==';') {
    id f = [Richfont new];
    [f setfontnum:fontnum];
    [f setfontfamily:fontfamily];
    p[n-1] = '\0';
    [f setfontname:p];
    [richtext addfont:f];
  }
  return self;
}

- addtotext:(char *)s count:(int)n
{
  unsigned p;
  int defaultfont = [richtext defaultfont];
  id ats,t,lastp = [richtext lastparagraph];

  t = [lastp text];
  p = [t size];

  [[t string] concatSTR:s]; /* expand string */
  ats = [t attributesAt:p]; 

  assert([ats isKindOf:OrdCltn] && [ats size] == 0);
  assert([t runLengthFor:p] == n);

  if (boldface) [ats add:[Boldface new]];
  if (italic) [ats add:[Italic new]]; 
  if (underlined) [ats add:[Underlined new]];
  if (fontnum!=defaultfont)[ats add:[[Fontchange new] setfontnum:fontnum]];
  if (fontsize!=FONTSIZE)[ats add:[[Fontsizechange new] setfontsize:fontsize]];

  return self;
}

- add:s
{
  [self addchars:[s str] count:[s size]];
  [s free];
  return self;
}

- addchars:(char *)s
{
  return [self addchars:s count:strlen(s)];
}

- addchars:(char *)s count:(int)n
{
  /* action of -add: depends on current destination */

  switch (destination) {
    case DIGNORE  : {
      break;
    }
    case DFNTABLE : {
      [self addfontnamed:s];
      break;
    }
    default : {
      [self addtotext:s count:n];
      break;
    }
  }

  return self;
}

@end

