
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

char *findafmfile(char *fn);

@interface AFM : Object 
{
  id fname;
  id FontName;
  id FullName;
  id FamilyName;
  id Weight;
  double ItalicAngle;
  BOOL IsFixedPitch;
  double FontBBox_llx; 
  double FontBBox_lly; 
  double FontBBox_urx; 
  double FontBBox_ury; 
  long UnderlinePosition;
  long UnderlineThickness;
  id Version;
  id Notice;
  id EncodingScheme;
  long CapHeight;
  long XHeight;
  long Ascender;
  long Descender;
  long MappingScheme;
  long EscChar;
  id CharacterSet;
  long Characters;
  BOOL IsBaseFont;
  double VVector_0;
  double VVector_1;
  BOOL IsFixedV;
  id BlendAxisTypes;
  id BlendDesignPositions;
  id BlendDesignMap;
  id WeightVector;
}

+ new;
+ open:(STR)filename;
- (long)Ascender;
- (long)Descender;
- bboxes;
- bboxAt:(int)c;

@end

