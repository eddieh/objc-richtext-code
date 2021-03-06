
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

@interface CharacterBlockScanner : CharacterScanner 
{
  int characterx,charactery;
  int characterindex;
  BOOL havecharacterindex;
  int nextleftmargin;
}

/* stop conditions */

- tab;
- space;
- newline;
- crossedx;
- endOfRun;

/* scanning */

- charBlockForIndex:(int)ci in:paragraph parindex:(int)pi;
- charBlockAtPoint:(int)x:(int)y in:paragraph parindex:(int)pi;

@end

