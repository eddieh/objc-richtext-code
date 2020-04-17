
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

#include <Object.h>
#include <ordcltn.h>
#include <ocstring.h>
#include <set.h>
#include <octext.h>
#include <txtattr.h>
#include <point.h>
#include <rectangl.h>
#include <paragrph.h>
#include <runarray.h>
#include <assert.h>
#include <setjmp.h>
#include <time.h>

#include "richtext.h"
#include "lexan.h"
#include "richfont.h"
#include "state.h"
#include "style.h"
#include "textline.h"
#include "fontchange.h"
#include "charblk.h"

@implementation Richtext 

int papersize;

typedef struct { char *name;int x;int y; } PAPERSIZE;
 
PAPERSIZE papsizes[] = {{"A4",595,842},{"Letter",612,792}};

int twips2points(int x)
{
  return ((x)/20);
}

int points2twips(int x) 
{
  return ((x)*20);
}

- docdefaults
{
  paperw = PAPERW;
  paperh = PAPERH;
  margl = MARGL;
  margr = MARGR;
  margt = MARGT;
  margb = MARGB;
  return self;
}

- empty
{
  if (paragraphs) {
    [[paragraphs freeContents] free];
  }
  [self docdefaults];
  [self paragraphs:[OrdCltn new]];
  [self newparagraph];
  return self;
}

#ifndef NDEBUG
- check
{
  if (paralines) {
    int i,n;
    n = [paragraphs size];
    assert([paralines size] == n);
    for(i=0;i<n;i++) {
      int j,m,pos;
      int txtsiz = [[[paragraphs at:i] text] size];
      id lines = [paralines at:i];
      for(pos=0,j=0,m=[lines size];j<m;j++) {
	pos = [[lines at:j] last];
	assert(pos < txtsiz); 
      }
      assert(txtsiz == 0 || pos+1 == txtsiz);
    }
  }

  return self;
}
#endif

+ new
{
  return [[super new] empty];
}

- free
{
  [displayscanner free];
  [compositionscanner free];
  [[paragraphs freeContents] free];
  return [super free];
}

- paragraphs:c
{
  paragraphs = c;
  return self;
}

- attributesAtBlock:aBlock
{
  id t;
  int i,j;
  i = [aBlock parindex];
  j = [aBlock stringindex];
  t = [[paragraphs at:i] text];
  return [t attributesAt:j];
}

- addnewlineAt:(int)i
{
  int n;
  id t = [[paragraphs at:i] text];
  assert(t);
  n = [t size];
  [[t string] concatSTR:"\n"];
  [t attributesAt:n];
  return self;
}

- addnewline
{
  return [self addnewlineAt:[paragraphs size] - 1];
}

- newparagraph
{
  id newp,lastp;
  if ((lastp = [self lastparagraph])) {
    if ([[lastp text] size] == 0) return self; /* don't have to do anything */
    /* style is inherited (can be reset with \pard) */
    newp = [Paragraph withText:[Text new] style:[[lastp textStyle] copy]];
  } else {
    newp = [Paragraph withText:[Text new] style:[Style new]];
  }
  [paragraphs add:newp];
  return self;
}

- paragraphs
{
  if (!paragraphs) paragraphs = [OrdCltn new];
  return paragraphs;
}

- paralines
{
  if (!paralines) paralines = [OrdCltn new];
  return paralines;
}

- lastparagraph
{
  return [paragraphs lastElement];
}

- laststyle
{
  return [[self lastparagraph] textStyle];
}

- afmset
{
  static id glbset;
  if (!glbset) glbset = [Set new];
  return glbset;
}

- xfontset
{
  if (!xfontset) xfontset = [Set new];
  return xfontset;
}

- addfont:f
{
  if (!fonts) fonts = [OrdCltn new];
  [fonts add:f];
  return self;
}

- adobefonts
{
  id c;

  c = [Richfont new];
  [c setfontnum:0];
  [c setfontfamily:FFROMAN];
  [c setfontname:"Times-Roman"];
  [self addfont:c];

  c = [Richfont new];
  [c setfontnum:1];
  [c setfontfamily:FFSWISS];
  [c setfontname:"Helvetica"];
  [self addfont:c];

  c = [Richfont new];
  [c setfontnum:0];
  [c setfontfamily:FFMODERN];
  [c setfontname:"Courier"];
  [self addfont:c];

  return self;
}

- fontwithnum:(int)fn
{
  int i,n = [fonts size];
  for(i=0;i<n;i++) {
    id f = [fonts at:i];
    if ([f fontnum] == fn) return f;
  }
  return nil;
}

- fontwithfamily:(int)fam
{
  int i,n = [fonts size];
  for(i=0;i<n;i++) {
    id f = [fonts at:i];
    if ([f fontfamily] == fam) return f;
  }

  /* no such font -- add the standard fonts to the font table */
  [self adobefonts]; return [self fontwithfamily:fam];
}

- (int)paperw
{
  return paperw;
}

- (int)paperh
{
  return paperh;
}

- setpaperw:(int)w
{
  paperw = w;
  return self;
}

- setpaperh:(int)h
{
  paperh = h;
  return self;
}

- setmargleft:(int)n
{
  margl = n;
  return self;
}

- setmargright:(int)n
{
  margr = n;
  return self;
}

- setmargtop:(int)n
{
  margt = n;
  return self;
}

- setmargbottom:(int)n
{
  margb = n;
  return self;
}

- (int)leftmarginIn:style forLine:(int)i
{
  if (i) {
    return twips2points(margl + [style leftindent]);
  } else {
    return twips2points(margl + [style leftindent] + [style firstindent]);
  }
}

- (int)rightmarginIn:style forLine:(int)i 
{
  return twips2points(paperw - margr - [style rightindent]);
}

- (int)psrightmarginIn:style forLine:(int)i 
{
  return papsizes[papersize].x - 2 * PSMARGIN - twips2points(margr + [style rightindent]);
}

- (int)defaultfont
{
  return defaultfont;
}

- setdefaultfont:(int)h
{
  defaultfont = h;
  return self;
}

- setcharacterset:(int)h
{
  characterset = h;
  return self;
}

- setpsdisplayscanner:aScanner
{
  if (psdisplayscanner) [psdisplayscanner free];
  psdisplayscanner = aScanner; /* external, platform specific */
  return self;
}

- setdisplayscanner:aScanner
{
  if (displayscanner) [displayscanner free];
  displayscanner = aScanner; /* external, platform specific */
  return self;
}

- setcharblockscanner:aScanner
{
  if (charblockscanner) [charblockscanner free];
  charblockscanner = aScanner; /* external, platform specific */
  return self;
}

- setpscompositionscanner:aScanner
{
  if (pscompositionscanner) [pscompositionscanner free];
  pscompositionscanner = aScanner; /* external, platform specific */
  return self;
}

- setcompositionscanner:aScanner
{
  if (compositionscanner) [compositionscanner free];
  compositionscanner = aScanner; /* external, platform specific */
  return self;
}

- stringfrom:startblock to:stopblock
{
  id t,s;
  int i,j,k,l,n;

  i = [startblock parindex];
  j = [startblock stringindex];
  k = [stopblock parindex];
  l = [stopblock stringindex];

  if (i == k) {
    t = [[paragraphs at:i] text];
    n = [t size];
    if (j<n && l<n && j<=l) {
      s = [String chars:[t str]+j count:l - j + 1];
    } else {
      s = [String new];
    }
  } else {
    t = [[paragraphs at:i] text];
    n = [t size];
    if (j<n) s = [String str:[t str] + j];else s = [String new];
    for(i++;i<k;i++) {
      t = [[paragraphs at:i] text];
      [s concatSTR:[t str]];
    }
    t = [[paragraphs at:i] text];
    n = [t size];
    if (l<n) {
      id z = [String chars:[t str] count:l + 1];
      [s concatSTR:[z str]]; /* there should be a concatchars:count: */
      [z free];
    }
  }

  return s;
}

- addAttribute:a fromblock:startblock toblock:stopblock
{
  id t = [OrdCltn with:1,a];
  [self addAttributes:t fromblock:startblock toblock:stopblock];
  [[t freeContents] free];
  return self;
}

- addAttributes:c to:text from:(int)i to:(int)j
{
  int ci,cn = [c size];
  for(ci=0;ci<cn;ci++) {
    id a = [c at:ci];
    if ([a istextattr]) {
       [text addAttribute:[a copy] from:i to:j];
    }
  }
  return self;
}

- addAttributes:c fromblock:startblock toblock:stopblock
{
  id t;
  int i,j,k,n;

  i = [startblock parindex];
  j = [startblock stringindex];
  k = [stopblock parindex];

  if (i == k) {
    t = [[paragraphs at:i] text];
    if ((n=[t size]) && (j<=n-1)) {
      [self addAttributes:c to:t from:j to:[stopblock stringindex]];
      [self composeAt:i];
    }

  } else {
    t = [[paragraphs at:i] text];
    if ((n=[t size]) && (j<=n-1)) {
      [self addAttributes:c to:t from:j to:(n-1)];
      [self composeAt:i];
    }

    for(i++;i<k;i++) {
      t = [[paragraphs at:i] text];
      if ((n=[t size])) {
        [self addAttributes:c to:t from:0 to:(n-1)];
	[self composeAt:i];
      }
    }

    j = [stopblock stringindex];
    t = [[paragraphs at:i] text];
    if ((n=[t size]) && (0<=j) && (j<n)) {
      [self addAttributes:c to:t from:0 to:j];
      [self composeAt:i];
    }
  }

  return self;
}

- atBlock:b insert:(char*)s count:(int)n
{
  int pi = [b parindex];
  int ci = [b stringindex];

  [[[paragraphs at:pi] text] at:ci insert:s count:n];

  [self composeAt:pi];
  return self;
}

- removeparAt:(int)i
{
  if ([paragraphs size] == 1 && i == 0) {
   [[paragraphs removeAt:i] free];
   if (paralines) paralines = [[paralines freeContents] free];
   [self newparagraph]; /* to avoid empty doc */
  } else {
   [[paragraphs removeAt:i] free];
   if (paralines) [[paralines removeAt:i] free];
  }
  return self;
}

- deleteFromBlock:a to:b
{
  int pi = [a parindex];
  int pj = [b parindex];
  int ci = [a stringindex];
  int cj = [b stringindex];

  id t = [[paragraphs at:pi] text];

  if (pi == pj) {
    int m = [t size];
    if (cj < m - 1) {
      [t deleteFrom:ci to:cj];
    } else {
      [t deleteFrom:ci to:m - 1];
      if (pi + 1 < [paragraphs size]) {
	id s = [[paragraphs at:pi+1] text];
	[t concat:s];
	[self removeparAt:pi+1];
      } else {
	[self addnewline]; /* this is to always add a newline at the end */
      }
    }
  } else {
    int i;
    id s = [[paragraphs at:pj] text];
    int m = [t size];
    int n = [s size];
    if (m) [t deleteFrom:ci to:m - 1];
    if (cj + 1 < n) {
      [s deleteFrom:0 to:cj];
      [t concat:s];
      for(i=pi+1;i<=pj;i++) [self removeparAt:pi+1];
    } else {
      if (pj + 1 < [paragraphs size]) {
	s = [[paragraphs at:pj+1] text];
	[t concat:s];
        for(i=pi+1;i<=pj+1;i++) [self removeparAt:pi+1];
      } else {
        for(i=pi+1;i<=pj;i++) [self removeparAt:pi+1];
	[self addnewline]; /* this is to always add a newline at the end */
      }
    }
  }

  return self;
}

- replaceFrom:a to:b with:(char*)s count:(int)n
{
  [self deleteFromBlock:a to:b];
  if (n) [self atBlock:a insert:s count:n];
  [self composeAt:[a parindex]];
  assert([self check]);
  return self;
}

- defaultCharBlock
{
  return [self notImplemented];
}

- charBlockAtPoint:(int)x:(int)y in:paragraph parindex:(int)i
{
  return [self shouldNotImplement];
}

- firstBlock
{
  return [self charBlockForIndex:0:0];
}

- lastBlock
{
  int n = [paragraphs size];
  int m = [[[paragraphs at:n-1] text] size];
  return [self charBlockForIndex:n-1:m-1];
}

- charBlockAtPoint:(int)x:(int)y
{
  int h;
  int i,n = [paragraphs size];

  if (y < 0) return [self firstBlock];

  for(i=0,h = 0;i<n;i++) {
    h += [self bottomOfLines:[paralines at:i]];
    if (y < h) {
      id p = [paragraphs at:i];
      return [charblockscanner charBlockAtPoint:x:y in:p parindex:i];
    }
  }

  if (n) {
    return [self lastBlock];
  } else {
    return [self error:"No paragraph at point %i %i",x,y];
  }
}

- charBlockForIndex:(int)ci in:paragraph parindex:(int)i
{
  return [self shouldNotImplement];
}

- charBlockForIndex:(int)pi:(int)ci
{
  id p = [paragraphs at:pi];
  return [charblockscanner charBlockForIndex:ci in:p parindex:pi];
}

- blockAfter:b
{
  int m,n;
  int pi = [b parindex];
  int ci = [b stringindex];

  n = [paragraphs size];
  m = [[[paragraphs at:pi] text] size];

  if (ci+1 < m) return [self charBlockForIndex:pi:ci+1];
  if (pi+1 < n) return [self charBlockForIndex:pi+1:0];
  return [b copy]; /* mmh */
}

- blockBefore:b
{
  int m,n;
  int pi = [b parindex];
  int ci = [b stringindex];

  n = [paragraphs size];

  if (ci-1 >= 0) return [self charBlockForIndex:pi:ci-1];
  if (pi-1 >= 0) {
    m = [[[paragraphs at:pi-1] text] size];
    if (m) --m;
    return [self charBlockForIndex:pi-1:m];
  }
  return [b copy]; /* mmh */
}

/* below/above could be improved to work line by line */

- blockBelow:b
{
  int m,n;
  int pi = [b parindex];
  int ci = [b stringindex];

  n = [paragraphs size];
  if (++pi < n) {
    m = [[[paragraphs at:pi] text] size];
    if (m) --m;
    if (ci > m) ci=m; 
    return [self charBlockForIndex:pi:ci];
  }

  return [b copy];
}

- blockAbove:b
{
  int m,n;
  int pi = [b parindex];
  int ci = [b stringindex];
  
  n = [paragraphs size];
  if (--pi >= 0) {
    m = [[[paragraphs at:pi] text] size];
    if (m) --m;
    if (ci > m) ci=m; 
    return [self charBlockForIndex:pi:ci];
  }

  return [b copy];
}

- composeLine:(int)i from:(int)from in:paragraph
{
  return [self shouldNotImplement];
}

- startpage:(int)n:(int)x:(int)y
{
  return [self shouldNotImplement];
}

- showpage
{
  return [self shouldNotImplement];
}

- displayLine:lines num:(int)i in:paragraph at:(int)liney
{
  return [self shouldNotImplement];
}

- composeAll
{
  int i,n;

  if (paralines) {
    [paralines elementsPerform:@selector(freeContents)];
    [paralines freeContents];
  } else {
    paralines = [OrdCltn new];
  }

  /* feed chars into external (platform specific) composition scanner */

  for(i=0,n=[paragraphs size];i<n;i++) {
    [self composeAt:i];
  }

  assert([self check]);
  return self;
}

- composeAt:(int)i
{
  id p = [paragraphs at:i];
  id lines = [OrdCltn new];
  int k,startindex,stopindex;

  startindex = 0;
  stopindex = [[p text] size];

  for(k=0;startindex<stopindex;k++) {
    id line=[compositionscanner composeLine:k from:startindex in:p]; 
    startindex = [line last] + 1;
    [lines add:line];
  }

  if (i < [paralines size]) {
    id old = [paralines at:i put:lines];
    [[old freeContents] free];
  } else {
    [paralines add:lines];
  }

  return self;
}

- printAt:(int)i
{
  id p = [paragraphs at:i];
  id lines = [OrdCltn new];
  int k,startindex,stopindex;

  startindex = 0;
  stopindex = [[p text] size];

  for(k=0;startindex<stopindex;k++) {
    id line=[pscompositionscanner composeLine:k from:startindex in:p]; 
    startindex = [line last] + 1;
    [lines add:line];
  }

  [psparalines add:lines];
  return self;
}

- printAll
{
  int i,n,y;
  PAPERSIZE p = papsizes[papersize];

  psparalines = [OrdCltn new];

  /* feed chars into external (platform specific) composition scanner */
  /* pscompositionscanner is usually a PS scanner, but may be e.g. PCL6 */

  for(i=0,n=[paragraphs size];i<n;i++) {
    [self printAt:i];
  }
  
  pagecount=1;
  [psdisplayscanner startpage:pagecount:p.x:p.y];

  for(i=0,y=0,n=[paragraphs size];i<n;i++) {
    int j,m;
    id lines = [psparalines at:i];
    for(j=0,m=[lines size];j<m;j++) {
      id line = [lines at:j];
      int lineheight = [line lineheight];
      if (y + lineheight> (p.y-2*PSMARGIN)) {
        y=0;[psdisplayscanner showpage];
        [psdisplayscanner startpage:++pagecount:p.x:p.y];
      } 
      [psdisplayscanner displayLine:line num:j in:[paragraphs at:i] at:y];
      y += lineheight;
    }
  }

  [psdisplayscanner showpage];
  [psparalines elementsPerform:@selector(freeContents)];
  [psparalines freeContents];
  return self;
}

- (int)bottomOfLines:cLines
{
  int h = 0;
  int i,n = [cLines size];
  for(i=0;i<n;i++) h += [[cLines at:i] lineheight];
  return h;
}

- (int)topAtLineIndex:(int)parindex:(int)lineindex
{
  id cLines;
  int i,h = 0;
  for(i=0;i<parindex;i++) h += [self bottomOfLines:[paralines at:i]];
  cLines = [paralines at:parindex];
  for(i=0;i<lineindex;i++) h += [[cLines at:i] lineheight];
  return h;
}

- (int)lineIndexOfCharacterIndex:(int)pari:(int)ci
{
  int i,n;
  id lines = [paralines at:pari];
  for(i=0,n=[lines size];i<n;i++) {
    if (ci <= [[lines at:i] last]) return i;
  }
  if (n) [self error:"No character at position %i.",ci];
  return 0;
}

- (int)lineIndexOfTop:(int)pari:(int)y
{
  int i,n;
  id lines = [paralines at:pari];
  int h = [self topAtLineIndex:pari:0];
  for(i=0,n=[lines size];i<n;i++) {
    h += [[lines at:i] lineheight];
    if (y < h) break;
  }
  if (i == n) {
    return (n)?n-1:0;
  } else {
    assert([self topAtLineIndex:pari:i] <= y && y < h);
    return i;
  }
}

- (int)top
{
  return top;
}

- top:(int)v
{
#ifndef NDEBUG
  int min = twips2points(paperh);
  int totalh = [self totalheight];
  if (totalh < min) min = totalh;
  if (v > totalh - min) [self error:"top larger than totalh - paperh"];
#endif
  top = v; return self;
}

- (int)totalheight
{
  int h = 0;
  int i,n = [paralines size];
  if (!paralines) [self composeAll]; 
  for(i=0;i<n;i++) h += [self bottomOfLines:[paralines at:i]];
  return h;
}

- setclip:(int)l:(int)t:(int)w:(int)h
{
  [displayscanner setclip:l:t:w:h];
  return self;
}

- displayLines:(int)t:(int)h
{
  int i,n,j,m;
  int y = -[self top];
  int a = t;
  int b = t + h;

  if (!paralines) [self composeAll];

  assert([paragraphs size] == [paralines size]);

  for(i=0,n=[paragraphs size];i<n;i++) {
    id lines = [paralines at:i];
    for(j=0,m=[lines size];j<m;j++) {
      id line = [lines at:j];
      int lineheight = [line lineheight];
      if (y+lineheight > a) {
	[displayscanner displayLine:line num:j in:[paragraphs at:i] at:y];
      }
      y += lineheight;
      if (y > b) return self;
    }
  }

  return self;
}

- errormsg:x
{
  if (errormsg) [errormsg free];
  errormsg = x;
  return self;
}

- (char*)errormsg
{
  return [errormsg str];
}

static jmp_buf jb;

static void readgroup(IOD d,id state)
{
  while (1) {
    int c;
    curstate = state;
    c = lexanlex();

    switch(c) {
      case OPENGR : {
	readgroup(d,[state copy]);
	break;
      }
      case EOF :
      case CLOSEGR : {
	[state free];
	return;
      }
      case PANICS : {
	longjmp(jb,1);
      }
      default : {
        lexanerrmsg=[String sprintf:"File not in RTF format.\nExpected '}' but got '%c'\n",c];
	longjmp(jb,1);
      }
    }
  }
}

- readrtf:(IOD)d
{
  lexanin = d;
  lineno = 1;
  lexanerrmsg = nil;

  /* start reading by default into destination 'self' */
  curstate = [[State new] richtext:self];

  if (lexanlex() == OPENGR) {
    if (lexanlex() == RTFWORD) {
      if (setjmp(jb) == 0) {
	readgroup(d,curstate);
	return self;
      }
    } else {
      [[self empty] adobefonts];
    }
  } else {
    [[self empty] adobefonts];
  }

  curstate = [curstate free];
  [self errormsg:(lexanerrmsg)?lexanerrmsg:[String str:"File not in RTF format"]];
  return nil;
}

static void writertfchar(IOD d,int c)
{
  switch(c) {
    case '\\' : 
      fprintf(d,"\\\\");
      break;
    case '\n' : 
      fprintf(d,"\\\n");
      break;
    case '{' : 
      fprintf(d,"\\{");
      break;
    case '}' : 
      fprintf(d,"\\}");
      break;
    default   :
      fputc(c,d);
      break;
  }
}

static void writekeyw(IOD d,id a)
{
  if ([a respondsTo:@selector(writertf:)]) [a writertf:d];
}

static BOOL isempty(id c)
{
  int cnt = 0;
  int i,n = [c size];
  for(i=0;i<n;i++) {
    if ([[c at:i] respondsTo:@selector(writertf:)]) cnt++;
  }
  return cnt == 0;
}

static void writertftext(IOD d,STR t,id runArray)
{
  unsigned size;
  unsigned p = 0;

  [runArray coalesce];
  
  size = [runArray size];
  assert(strlen(t) == size);

  while (p < size) {
    int i,n;
    id attrs;
    unsigned q;
    attrs = [runArray at:p];
    n = [attrs size];
    q = p + [runArray runLengthAt:p];
    assert(q != p && q <= size);
    if (isempty(attrs)) {
      for(;p<q;p++) writertfchar(d,*t++);
    } else {
      fprintf(d,"{");
      for(i=0;i<n;i++) writekeyw(d,[attrs at:i]);
      fprintf(d," ");
      for(;p<q;p++) writertfchar(d,*t++);
      fprintf(d,"}");
    }
  }
}

- writertf:(IOD)d
{
  int i,n;
  id prevstyle = nil;
  fprintf(d,"{\\rtf1");
  switch(characterset) {
    case CSANSI : fprintf(d,"\\ansi");break;
    case CSMAC  : fprintf(d,"\\mac");break;
    case CSPC   : fprintf(d,"\\pc");break;
    case CSPCA  : fprintf(d,"\\pca");break;
    default     : assert(0);break;
  }
  fprintf(d,"\\deff%d",defaultfont);
  fprintf(d,"{\\fonttbl");
  for(i=0,n=[fonts size];i<n;i++) {
    [[fonts at:i] writertf:d];
  }
  fprintf(d,"}");
  if (paperw!=PAPERW) fprintf(d,"\\paperw%d",paperw);
  if (paperh!=PAPERH) fprintf(d,"\\paperh%d",paperh);
  if (margl!=MARGL) fprintf(d,"\\margl%d",margl);
  if (margr!=MARGR) fprintf(d,"\\margr%d",margr);
  if (margt!=MARGT) fprintf(d,"\\margt%d",margt);
  if (margb!=MARGB) fprintf(d,"\\margb%d",margb);
  for(i=0,n=[paragraphs size];i<n;i++) {
    id p = [paragraphs at:i];
    id mystyle = [p textStyle];
    /* to make style less verbose, use inherit style feature of RTF */
    if (prevstyle && ![mystyle isEqual:prevstyle]) [mystyle writertf:d];
    writertftext(d,[[p text] str],[[p text] runs]); 
    prevstyle = mystyle;
  }
  fprintf(d,"}\n\n");
  return self;
}

- writeplain:(IOD)d
{
  /* ignore all style, just dumps plain text */
  int i,n;
  for(i=0,n=[paragraphs size];i<n;i++) {
    id p = [paragraphs at:i];
    fprintf(d,[[p text] str]);
  }
  return self;
}

- setpsiod:(IOD)d
{
  [psdisplayscanner setpsiod:d];
  return self;
}

- writepostscript:(IOD)d
{
  time_t t;
  PAPERSIZE p = papsizes[papersize];
  if (pscompositionscanner == nil || psdisplayscanner == nil) {
    [self error:"-setpscompositionscanner: must be sent first"];
  }
  [self setpsiod:d];
  time(&t);
  fprintf(d,"%%!PS-Adobe-3.0\n");
  fprintf(d,"%%%%Title: rt output\n");
  fprintf(d,"%%%%For: rt user\n");
  fprintf(d,"%%%%Creator: rt 0.1.6\n");
  fprintf(d,"%%%%CreationDate: %s",ctime(&t));
  fprintf(d,"%%%%Orientation: Portrait\n");
  fprintf(d,"%%%%Pages: (atend)\n");
  fprintf(d,"%%%%DocumentMedia: %s %d %d 0 () ()\n",p.name,p.x,p.y);
  fprintf(d,"%%%%DocumentNeededResources: (atend)\n");
  [self printAll];
  fprintf(d,"%%%%Trailer\n");
  fprintf(d,"%%%%Pages: %d\n",pagecount);
  fprintf(d,"%%%%EOF\n");
  return self;
}

- selrects
{
  return selrects;
}

- removeselrects
{
  if (selrects) selrects = [[selrects freeContents] free];
  return self;
}

- getrectsfrom:startblock to:stopblock
{
  id o,c;
  id line;
  int l,w;
  id rects = [OrdCltn new];

  assert([startblock compare:stopblock] <= 0);

  if ((line=[startblock textLine]) && line == [stopblock textLine]) {
    o = [[startblock origin] copy];
    c = [[stopblock corner] copy];
    [rects add:[Rectangle origin:o corner:c]];
    return rects;
  } 

  w = twips2points(paperw - margr);
  l = twips2points(margl);

  o = [[startblock origin] copy];
  c = [Point x:w y:[startblock bottom]];
  [rects add:[Rectangle origin:o corner:c]];

  if ([startblock bottom] < [stopblock top]) {
    o = [Point x:l y:[startblock bottom]];
    c = [Point x:w y:[stopblock top]];
    [rects add:[Rectangle origin:o corner:c]];
  }

  o = [Point x:l y:[stopblock top]];
  c = [[stopblock corner] copy];
  [rects add:[Rectangle origin:o corner:c]];

  return rects;
}

- selrectsfrom:startblock to:stopblock
{
  [self removeselrects];
  selrects = [self getrectsfrom:startblock to:stopblock];
  return self;
}

@end

