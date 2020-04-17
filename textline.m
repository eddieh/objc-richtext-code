
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

#include <assert.h>
#include <Object.h>
#include "textline.h"

@implementation TextLine 

- (int)last
{
  return last;
}

- (int)first
{
  return first;
}

- start:(int)offset
{
  first = offset;return self;
}
 
- stop:(int)offset
{
  last = offset;return self;
}

- (int)ascent
{
  return ascent;
}

- (int)descent
{
  return descent;
}

- ascent:(int)a descent:(int)d
{
  ascent = a;descent = d;return self;
}

- paddingwidth:(int)pw
{
  paddingwidth = pw;return self;
}

- spacecount:(int)cnt
{
  spacecount = cnt;return self;
}

- (int)lineheight
{
  return ascent + descent;
}

- (int)spacecount
{
  return spacecount;
}

- (int)paddingwidth
{
  return paddingwidth;
}

@end

