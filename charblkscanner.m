
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
#include <point.h>
#include <rectangl.h>
#include <ordcltn.h>
#include <octext.h>
#include <paragrph.h>
#include "charblk.h"

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#undef Object
#undef String

#include "charscanner.h"
#include "charblkscanner.h"
#include "richtext.h"
#include "textline.h"
#include "style.h"

#define IGNORE_LASTH 1

@implementation CharacterBlockScanner 

- setdestx
{
  switch([textStyle alignment]) {
    case ALGNLEFT  : destx = leftmargin;break;
    case ALGNRIGHT : destx = leftmargin + [line paddingwidth];break;
    case ALGNCENTER: destx = leftmargin + [line paddingwidth]/2;break;
    case ALGNJUST  : destx = leftmargin;break;
  }
  return self;
}

- space
{
  stopscanning = NO;
  destx += spacewidth;
  ++spacecount;
  ++lastindex;
  return self;
}

- tab
{
  stopscanning = NO;
  destx = [textStyle nextTabfromx:destx leftmargin:leftmargin rightmargin:rightmargin]; 
  ++lastindex;
  return self;
}

- newline
{
  stopscanning = YES;
  characterx = destx;
#if IGNORE_LASTH
  charactery = desty;
#else
  charactery = desty + [line ascent] - lastcharascent;
#endif
  lastcharw = rightmargin - destx;
  return self;
}

- crossedx
{
  stopscanning = YES;
  characterx = destx;
#if IGNORE_LASTH
  charactery = desty;
#else
  charactery = desty + [line ascent] - lastcharascent;
#endif
  return self;
}

- endOfRun /* one char past last run */
{
  assert(lastindex == runstopindex + 1);

  if ((havecharacterindex == 1 && lastindex <= characterindex) || (havecharacterindex == 0 && lastindex <= [line last])) {

    stopscanning = NO;
    runstopindex = lastindex + [text runLengthFor:lastindex] - 1;

    if (havecharacterindex) {
      if (runstopindex > characterindex) runstopindex = characterindex;
    } else {
      if (runstopindex > [line last]) runstopindex = [line last];
    }

    [self setfont];
  } else {
    if (havecharacterindex && runstopindex == characterindex) {
      --lastindex;
      characterx = destx - lastcharw;
#if IGNORE_LASTH 
      charactery = desty;
#else
      charactery = desty + [line ascent] - lastcharascent;
#endif
      stopscanning = YES;
    } else {
      stopscanning = YES;
    }
  }
  return self;
}

- buildCharBlock:(int)parindex
{
  id rect = [CharacterBlock new];
  id lines = [[richtext paralines] at:parindex];

  if ([lines size] == 0 || [text size] == 0) {
    int left,top;
    [rect textLine:nil];
    [rect richtext:richtext parindex:parindex stringindex:0];
    left = [richtext leftmarginIn:textStyle forLine:0];
    top  = [richtext topAtLineIndex:parindex:0];
    [rect origin:[Point x:left y:top] corner:[Point x:left y:top]];
    return rect;
  } else {
    int lineindex = [richtext lineIndexOfTop:parindex:charactery];
    desty = [richtext topAtLineIndex:parindex:lineindex]; 
    line = [[[richtext paralines] at:parindex] at:lineindex];
    rightmargin = [richtext rightmarginIn:textStyle forLine:lineindex];
    if (characterx > rightmargin) characterx = rightmargin;
    leftmargin = [richtext leftmarginIn:textStyle forLine:lineindex];
    nextleftmargin = [richtext leftmarginIn:textStyle forLine:lineindex+1];
    [self setdestx];
    lastindex = [line first];
    runstopindex = lastindex + [text runLengthFor:lastindex] - 1;

    if (havecharacterindex) {
      if (runstopindex > characterindex) runstopindex = characterindex;
    } else {
      if (runstopindex > [line last]) runstopindex = [line last];
    }

    spacecount = 0;
    lastcharw = 0;
    lastcharh = [line lineheight];

    [self setfont]; /* should also be set by endOfRun */ 

    displaying = NO;
    stopscanning = NO;
    while (!stopscanning) {
      id s = [text string];
      [self scancharsfrom:lastindex to:runstopindex in:s rightx:characterx];
    }

#if IGNORE_LASTH 
    lastcharh = [line lineheight];
#endif

    [rect origin:[Point x:characterx y:charactery] corner:[Point x:characterx+lastcharw y:charactery+lastcharh]];
    [rect richtext:richtext parindex:parindex stringindex:lastindex];
    [rect textLine:line];
    return rect;
  }
}

- charBlockForIndex:(int)ci in:paragraph parindex:(int)i
{
  int lineindex;
  [self setparagraph:paragraph];
  characterindex = ci;
  havecharacterindex = YES;
  characterx = [richtext rightmarginIn:textStyle forLine:-1]; 
  lineindex = [richtext lineIndexOfCharacterIndex:i:ci];
  charactery = [richtext topAtLineIndex:i:lineindex];
  return [self buildCharBlock:i];
}

- charBlockAtPoint:(int)x:(int)y in:paragraph parindex:(int)i
{
  [self setparagraph:paragraph];
  characterx = x;
  charactery = y;
  havecharacterindex = NO;
  return [self buildCharBlock:i];
}

@end

