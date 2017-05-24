/* 
 *	Luca Filippin - April 2010 - luca.filippin@gmail.com
 *  Copyright 2010 Language, Cognition and  Development Laboratory, Sissa, Trieste. All rights reserved.
 *
 */

#ifndef __T2T_PRINT_H__
#define __T2T_PRINT_H__

#include <stdio.h>
#include <stdarg.h>

// These are utilities to redirect talk2tobii logging msg
FILE *t2tOutputFile(FILE *F);
int t2tOutputFileName(char *fname, char *mode);
int t2tPrintf(const char *fmt, ...);

#endif
