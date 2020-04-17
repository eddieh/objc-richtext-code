
/*
 * Copyright (C) 1998,1999 David Stes.
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

#define FFDEFAULT 0
#define FFROMAN   1
#define FFSWISS   2
#define FFMODERN  3

@interface Richfont : Object
{
  int fontnum;
  int fontfamily;
  id fontname;
}

- (int)fontnum;
- (int)fontfamily;
- (char*)fontname;
- setfontnum:(int)num;
- setfontfamily:(int)fam;
- setfontname:(char*)s;

- writertf:(IOD)d;

@end

