
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
#include <ocstring.h>
#include <assert.h>
#include "richfont.h"

@implementation Richfont 

- (int)fontnum
{
  return fontnum;
}

- setfontnum:(int)num
{
  fontnum = num;return self;
}

- (int)fontfamily
{
  return fontfamily;
}

- setfontfamily:(int)fam
{
  fontfamily = fam;return self;
}

- (char*)fontname
{
  return [fontname str];
}

- setfontname:(char*)s
{
  fontname = [String str:s];return self;
}

- writertf:(IOD)d
{
  fprintf(d,"{");
  fprintf(d,"\\f%d",fontnum);
  switch(fontfamily) {
    case FFDEFAULT : fprintf(d,"\\fnil");break;
    case FFROMAN   : fprintf(d,"\\froman");break;
    case FFSWISS   : fprintf(d,"\\fswiss");break;
    case FFMODERN  : fprintf(d,"\\fmodern");break;
    default : assert(0);break;
  }
  fprintf(d," %s;",[fontname str]);
  fprintf(d,"}");
  return self;
}

@end

