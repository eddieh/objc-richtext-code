
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

#include <objc.h>
#include <ocstring.h>
#include <ordcltn.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define Object XtObject
#define String XtString
#include <X11/Intrinsic.h>
#include <Xm/Xm.h>
#undef Object
#undef String

#include "document.h"
#include "main.h"
#include "menu.h"
#include "panic.h"
#include "richtext.h"
#include "charscanner.h"
#include "compscanner.h"
#include "dispscanner.h"

Display *maindisplay;
XtAppContext maincontext;

static char *fallbackrsrcs[] = {
 "*richtext.blinkrate: 250",
 "*richtext.autoscroll: 50",
 "*richtext.background: white",
 "*richtext.foreground: black",
 "*richtext.swissbold:-adobe-helvetica-bold-r-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.swissplain:-adobe-helvetica-medium-r-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.swissitalic:-adobe-helvetica-medium-o-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.swissbolditalic:-adobe-helvetica-bold-o-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.modernbold:-adobe-courier-bold-r-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.modernplain:-adobe-courier-medium-r-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.modernitalic:-adobe-courier-medium-o-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.modernbolditalic:-adobe-courier-bold-o-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.romanbold:-adobe-times-bold-r-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.romanplain:-adobe-times-medium-r-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.romanitalic:-adobe-times-medium-i-normal-*-*-*-*-*-*-*-*-*",
 "*richtext.romanbolditalic:-adobe-times-bold-i-normal-*-*-*-*-*-*-*-*-*",
 "*multiClickTime: 500",
 "*menubar.marginHeight: 1",
 "*text.selectionArrayCount: 3",
 "*fontList:-adobe-helvetica-bold-r-normal-*-12-*-*-*-*-*-*-*",
 "*background: #b3b3b3",
 "*foreground: black",
#if 0
 "*richtext.background: #e5e5e5",
#endif
 "*XmList*foreground: black",
 "*XmList*background: #cccccc",
 "*XmTextField*background: #cccccc",
 "*XmTextField*foreground: black",
 "*filemenu.mnemonic: F",
 "*filemenu.new.accelerator: Ctrl<Key>n",
 "*filemenu.new.acceleratorText: Ctrl+N",
 "*filemenu.open.accelerator: Ctrl<Key>o",
 "*filemenu.open.acceleratorText: Ctrl+O",
 "*filemenu.close.accelerator: Ctrl<Key>w",
 "*filemenu.close.acceleratorText: Ctrl+W",
 "*filemenu.save.accelerator: Ctrl<Key>s",
 "*filemenu.save.acceleratorText: Ctrl+S",
 "*filemenu.saveas.accelerator: Shift Ctrl<Key>s",
 "*filemenu.saveas.acceleratorText: Ctrl+Shift+S",
 "*filemenu.revert.accelerator: Ctrl<Key>u",
 "*filemenu.revert.acceleratorText: Ctrl+U",
 "*filemenu.print.accelerator: Ctrl<Key>p",
 "*filemenu.print.acceleratorText: Ctrl+P",
 "*filemenu.exit.accelerator: Ctrl<Key>q",
 "*filemenu.exit.acceleratorText: Ctrl+Q",
 "*editmenu.mnemonic: E",
 "*editmenu.cut.accelerator: Ctrl<Key>x",
 "*editmenu.cut.acceleratorText: Ctrl+X",
 "*editmenu.copy.accelerator: Ctrl<Key>c",
 "*editmenu.copy.acceleratorText: Ctrl+C",
 "*editmenu.paste.accelerator: Ctrl<Key>v",
 "*editmenu.paste.acceleratorText: Ctrl+V",
 "*editmenu.delete.acceleratorText: Del",
 "*editmenu.selectall.accelerator: Ctrl<Key>a",
 "*editmenu.selectall.acceleratorText: Ctrl+A",
 "*searchmenu.mnemonic: S",
 "*searchmenu.find.accelerator: Ctrl<Key>f",
 "*searchmenu.find.acceleratorText: Ctrl+F",
 "*searchmenu.entersel.accelerator: Ctrl<Key>e",
 "*searchmenu.entersel.acceleratorText: Ctrl+E",
 "*searchmenu.findnext.accelerator: Ctrl<Key>g",
 "*searchmenu.findnext.acceleratorText: Ctrl+G",
 "*searchmenu.findprevious.accelerator: Ctrl<Key>d",
 "*searchmenu.findprevious.acceleratorText: Ctrl+D",
 "*searchmenu.replace.accelerator: Ctrl<Key>r",
 "*searchmenu.replace.acceleratorText: Ctrl+R",
 "*searchmenu.jump.accelerator: Ctrl<Key>j",
 "*searchmenu.jump.acceleratorText: Ctrl+J",
 "*fontmenu.mnemonic: t",
 "*sizemenu.mnemonic: S",
 "*stylemenu.mnemonic: y",
 "*stylemenu.bold.accelerator: Ctrl<Key>b",
 "*stylemenu.bold.acceleratorText: Ctrl+B",
 "*stylemenu.italic.accelerator: Ctrl<Key>i",
 "*stylemenu.italic.acceleratorText: Ctrl+I",
 "*windowsmenu.mnemonic: W",
 0
};

static char usagemsg[] =
"Usage:  richtext (v0.1.6) [-a4] [-us] [-ps] [-d] [-u] [-t] [-ascii] [-display [host]:server[.screen]\n\
	       [-geometry geometry] [-xrm resourcestring]\n\
	       [file...]\n";

static void mywarnhandler(char *msg)
{
    if (strstr(msg, "XtRemoveGrab"))
	      return;
    if (strstr(msg, "Attempt to remove non-existant passive grab"))
	      return;
    fprintf(stderr, msg);
}

static id rtfdirs;
static char* rtfpath;

char* findafmfile(char *fn)
{
  int n = strlen(fn);
  if (n == 0 || rtfdirs == nil || fn[0] == '/') {
    return fn;
  } else {
    int i;
    char buf[FILENAME_MAX+1];
    for(i=0;i<[rtfdirs size];i++) {
      sprintf(buf,"%s/%s",[[rtfdirs at:i] str],fn);
      if (access(buf,F_OK) == 0) {
	char *r = (char*)malloc(strlen(buf)+1);
	strcpy(r,buf);
	return r;
      }
    }
    return fn;
  }
}

static char* findrtffile(char *fn)
{
  int n = strlen(fn);
  if (n == 0 || rtfdirs == nil || fn[0] == '/') {
    return fn;
  } else {
    int i;
    char buf[FILENAME_MAX+1];
    for(i=0;i<[rtfdirs size];i++) {
      if (n <= 4 || strcmp(fn+n-4,".rtf")) {
	sprintf(buf,"%s/%s.rtf",[[rtfdirs at:i] str],fn);
      } else {
	sprintf(buf,"%s/%s",[[rtfdirs at:i] str],fn);
      }
      if (access(buf,F_OK) == 0) {
	char *r = (char*)malloc(strlen(buf)+1);
	strcpy(r,buf);
	return r;
      }
    }
    return fn;
  }
}

static void checkversion(void)
{
  int a,b,c;
  char *msg = "Requires objpak 1.10.10 or higher.\n";
  sscanf([Object objcrtRevision],"%d.%d.%d",&a,&b,&c);
  if (a == 1 && b < 10) {fprintf(stderr,msg);exit(0);}
  if (a == 1 && b == 10 && c < 10) {fprintf(stderr,msg);exit(0);}
}

int main(int n,char **v)
{
  int i;
  int psflag = 0;
  int checkopt = 0;
  int plainflag = 0;
  int filterflag = 0;

  checkversion();

  while (n>1) {
    if (strcmp(v[1],"-d")==0) { n--;v++;filterflag++;continue; }
    if (strcmp(v[1],"-debug")==0) { n--;v++;filterflag++;continue; }
    if (strcmp(v[1],"-ps")==0) { n--;v++;psflag++;continue; }
    if (strcmp(v[1],"-t")==0) { n--;v++;plainflag++;continue; }
    if (strcmp(v[1],"-ascii")==0) { n--;v++;plainflag++;continue; }
    if (strcmp(v[1],"-a4")==0) { n--;v++;papersize=PSIZE_A4;continue; }
    if (strcmp(v[1],"-us")==0) { n--;v++;papersize=PSIZE_USLetter;continue; }
    break;
  }

  if ((rtfpath = getenv("RTFPATH"))) {
    char *d;
    rtfdirs = [OrdCltn new];
    for(i=0,d=strtok(rtfpath,":");d;d=strtok(NULL,":")) {
      [rtfdirs add:[String str:d]];
    }
  }

  if (filterflag || plainflag || psflag) {
    id rt = [Richtext new];
    if (n != 1) {
      fprintf(stderr,"%s",usagemsg);exit(0);
    }
    if (![rt readrtf:stdin]) {
      fprintf(stderr,"Error: %s\n",[rt errormsg]);
      exit(1);
    } else {
      if (filterflag) [rt writertf:stdout];
      if (plainflag) [rt writeplain:stdout];
      if (psflag) {
        id scanner;
        scanner = [DisplayScanner new];
        [[scanner setrichtext:rt] setpsrender];
        [rt setpsdisplayscanner:scanner];
        scanner = [CompositionScanner new];
        [[scanner setrichtext:rt] setpsrender];
        [rt setpscompositionscanner:scanner];
        [rt writepostscript:stdout];
      }
      exit(0);
    }
  }

  XtToolkitInitialize();
  maincontext = XtCreateApplicationContext();

  XtSetWarningHandler(mywarnhandler);

  XtAppSetFallbackResources(maincontext,fallbackrsrcs);

  if ( (maindisplay = XtOpenDisplay (maincontext, NULL, APP_NAME, APP_CLASS, NULL,0,&n,v)) == NULL) {
    XtWarning ("richtext: Can't open display\n");
    exit(0);
  }

  addactions(maincontext);

  for(i=1;i<n;i++) {
    if (strcmp(v[i],"-u")==0) { dblbuf=0;continue; }
    if (strcmp(v[i],"-")==0) {
      checkopt++;
    } else {
      if (checkopt || strncmp(v[i],"-",1)) {
	[Document open:findrtffile(v[i])];
      } else {
	fprintf(stderr,"%s",usagemsg);exit(0);
      }
    }
  }

  if ([[Document documents] size] == 0) {
    [Document new];
  }

  XtAppMainLoop(maincontext);
  return 0;
}

