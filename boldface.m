
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

#include <string.h>
#include <txtattr.h>
#include "boldface.h"

@implementation Boldface 

static id me;

- (BOOL)istextattr
{
  return YES;
}

+ new
{
  if (!me) me = [super new];
  return me;
}

- copy
{
  return self;
}

- deepCopy
{
  return self;
}

- free
{
  return nil;
}

- (BOOL)dominates:b
{
  if (b == me) return YES;
  if (![b istextattr]) return YES;
  return NO;
}

- (BOOL)isEqual:b
{
  return b == me;
}

- writertf:(IOD)d
{
  fprintf(d,"\\b");
  return self;
}

@end

