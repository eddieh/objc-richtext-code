
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

#include <Object.h>
#include <rectangl.h>
#include <ordcltn.h>
#include "charblk.h"
#include "richtext.h"

@implementation CharacterBlock 

- copy
{
  return [super copy];
  /* Rectangle <1.10.10 bug : didn't bytecopy ! meanwhile fixed */
}

- deepCopy
{
  return [self copy];
}

- textLine:aLine
{
  textLine = aLine;
  return self;
}

- richtext:rt parindex:(int)pi stringindex:(int)ci
{
  richtext = rt;
  parindex = pi;
  stringindex = ci;
  return self;
}

- textLine
{
  return textLine;
}

- (int)parindex
{
  return parindex;
}

- (int)stringindex
{
  return stringindex;
}

- (int)compare:b
{
  int c;
  if (self==b) return 0;
  if ((c = parindex - [b parindex])) return c;
  return stringindex - [b stringindex];
}

- (BOOL)isEqual:b
{
  if (self==b) return YES;
  return (parindex == [b parindex] && stringindex == [b stringindex]);
}

@end

