
/*
 * Copyright (C) 1999 David Stes.
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
#include "bbox.h"

@implementation BoundingBox 

- setcharname:x
{
  charname = x;return self;
}

- setcharcode:(int)x
{
  charcode = x;return self;
}

- setwx:(int)x
{
  wx = x;return self;
}

- (int)wx
{
  return wx;
}

- charname
{
  return charname;
}

- (int)charcode
{
  return charcode;
}

@end

