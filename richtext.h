
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


#define PSIZE_A4 0
#define PSIZE_USLetter 1
extern int papersize;
#define PSMARGIN 24

#if 0
/* those are defaults per Microsoft Spec (RTF 1.3) */
#define PAPERW 12240
#define PAPERH 15840
#else
/* this looks nicer */
#define PAPERW 12000
#define PAPERH 8000
#endif
#define MARGL  1800
#define MARGR  1800
#define MARGT  1440
#define MARGB  1440

#define CSANSI 0
#define CSMAC  1
#define CSPC   2
#define CSPCA  3

int twips2points(int x);
int points2twips(int x); 

@interface Richtext : Object
{
  id fonts;
  id afmset;
  id xfontset;
  id paralines;
  id psparalines;
  id paragraphs;
  id errormsg;
  int paperw,paperh;
  int margl,margr,margt,margb;
  int defaultfont;
  int characterset;
  id psdisplayscanner;
  id pscompositionscanner;
  id displayscanner;
  id compositionscanner;
  id charblockscanner;
  int top;
  id selrects;
  int pagecount;
}

+ new;
- newparagraph;
- paragraphs:c;
- addfont:f;
- afmset;
- xfontset;
- adobefonts;
- addnewline;
- fontwithnum:(int)num;
- fontwithfamily:(int)fam;
- free;

- paragraphs;
- paralines;
- lastparagraph;
- laststyle;

- attributesAtBlock:aBlock;
- stringfrom:startblock to:stopblock;
- addAttribute:anAttrib fromblock:startblock toblock:stopblock;
- addAttributes:attrs fromblock:startblock toblock:stopblock;
- atBlock:b insert:(char*)s count:(int)n;
- replaceFrom:a to:b with:(char*)s count:(int)n;

- (int)paperw;
- (int)paperh;
- setpaperw:(int)w;
- setpaperh:(int)h;

- setmargleft:(int)n;
- setmargright:(int)n;
- setmargtop:(int)n;
- setmargbottom:(int)n;

- (int)leftmarginIn:style forLine:(int)i;
- (int)rightmarginIn:style forLine:(int)i;
- (int)psrightmarginIn:style forLine:(int)i;

- setcharacterset:(int)e;
- (int)defaultfont;
- setdefaultfont:(int)num;

- setpsdisplayscanner:aScanner;
- setpscompositionscanner:aScanner;
- setdisplayscanner:aScanner;
- setcompositionscanner:aScanner;
- setcharblockscanner:aScanner;

- defaultCharBlock;
- charBlockAtPoint:(int)x:(int)y;
- charBlockForIndex:(int)pi:(int)ci;
- blockAfter:b;
- blockBefore:b;
- blockBelow:b;
- blockAbove:b;

- composeAll;
- composeAt:(int)i;

- displayLines:(int)top:(int)height;
- setclip:(int)left:(int)top:(int)width:(int)height;

- selrects;
- removeselrects;
- selrectsfrom:startblock to:endblock;

- (char*)errormsg;
- readrtf:(IOD)d;
- writertf:(IOD)d;
- writeplain:(IOD)d;
- writepostscript:(IOD)d;

- (int)top;
- top:(int)v;
- (int)totalheight;
- (int)bottomOfLines:cLines;
- (int)topAtLineIndex:(int)pi:(int)li;
- (int)lineIndexOfTop:(int)pi:(int)y;
- (int)lineIndexOfCharacterIndex:(int)pi:(int)ci;

@end

