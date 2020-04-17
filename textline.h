
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

@interface TextLine : Object 
{
  int first,last;
  int ascent,descent;
  int paddingwidth;
  int spacecount;
}

- (int)last;
- (int)first;
- start:(int)offset;
- stop:(int)offset;
- (int)ascent;
- (int)descent;
- (int)lineheight;
- ascent:(int)a descent:(int)d;
- (int)paddingwidth;
- paddingwidth:(int)pw;
- (int)spacecount;
- spacecount:(int)cnt;

@end

