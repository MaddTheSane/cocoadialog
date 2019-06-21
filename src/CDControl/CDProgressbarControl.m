/*
	CDProgressbarControl.m
	CocoaDialog
	Copyright (C) 2004 Mark A. Stratman <mark@sporkstorms.org>
 
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.
 
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
 
	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "CDProgressbarControl.h"
#include <sys/select.h>
#include <sys/_select.h>

/*
 NOTE: I'm using C's select to do the non-blocking reading of stdin.
 If you can get it to work with purely NSFileHandle, let me know.
 */

@implementation CDProgressbarControl

- (NSDictionary *) availableKeys
{
	NSNumber *vOne = [NSNumber numberWithInt:CDOptionsOneValue];
	NSNumber *vNone = [NSNumber numberWithInt:CDOptionsNoValues];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
		vOne,  @"text",
		vOne,  @"percent",
		vNone, @"indeterminate",
		nil];
}

// Helper for _readData:.
// Take NSData obj read from stdin and break it into two strings separated by
// the first space. Returns NSArray with those two values (may be empty), or
// have only one element.
- (NSArray *) _parseData:(NSData *)data
{
	NSScanner *scanner;
	NSCharacterSet *whitespaceSet;
	NSString *stringIn;
	NSString *percent = nil; 
	NSString *newLabel = nil;

	whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	if ([data length]) {
		// I'm copying this into a separate char* so i can explicitly
		// null-terminate it.  When i just do
		// [NSString stringWithUTF8String:[data bytes]]
		// it's all 31 flavors of fucked up (every now and then it
		// inserts a '}' after the newline). I have no idea why, or
		// what's going on.
		// Wout: Maybe Unicode chars being cut in half by the buffer size?
		char *bytes = (char*)malloc(sizeof(char)*[data length] + 1);
		bytes = memcpy(bytes, [data bytes], [data length]);
		*(bytes+[data length]) = '\0';
		stringIn = [NSString stringWithUTF8String:bytes];
		free(bytes);
	} else {
		return [NSArray arrayWithObjects:@"", nil, nil];
	}

	// remove trailing newlines/returns
	while ([stringIn length] > 0 
	       && [[stringIn substringFromIndex:[stringIn length]-1] isEqualToString:@"\n"])
	{
		stringIn = [stringIn substringToIndex:[stringIn length]-1];
	}
	if ([stringIn length] == 0) {
		return [NSArray arrayWithObjects:@"", nil, nil];
	}

	// If we've read in multiple lines, use the second to last one.
	// (The last line is often cut off).
	NSArray *lines = [stringIn componentsSeparatedByString:@"\n"];
	if ([lines count] > 1) {
		stringIn = [lines objectAtIndex:[lines count]-2];
	}

	scanner = [NSScanner scannerWithString:stringIn];
	if ([scanner scanUpToCharactersFromSet:whitespaceSet intoString:&percent]) {
		newLabel = [stringIn substringFromIndex:[scanner scanLocation]];
	} // else it'll return an empty array (nil termination on this NSArray method)
	return [NSArray arrayWithObjects:percent, newLabel, nil];
}

// returns CDProgressbarMIN (0.0) if it doesn't otherwise get something good.
// uses NSString's doubleValue method, so "4.0123blah" will return 4.0123
- (double) _percentFromString:(NSString *)string
{
	double initialPercent;
	if (string == nil) return CDProgressbarMIN;
	initialPercent = [string doubleValue];
	if (initialPercent < CDProgressbarMIN 
	    || initialPercent > CDProgressbarMAX)
	{
		initialPercent = CDProgressbarMIN;
	}
	return initialPercent;
}

// takes the NSData from the NSFileHandle's availableData and tries to do 
// something useful with it.
- (void) _readData:(NSData *)data
{
	if (data == nil) {
		return;
	}
	
	if ([data length] > 0) {
		double newPercent;
		NSString *newLabel;
		NSArray *stuff = [self _parseData:data];
		if (stuff != nil && [stuff count] >= 1) {
			newPercent = [self _percentFromString:
				[stuff objectAtIndex:0]];
			if (![[self options] hasOpt:@"indeterminate"]) {
				[progressBar setDoubleValue:newPercent];
			}
			newLabel = [stuff count] > 1 ? 
				[stuff objectAtIndex:1] : nil;
			if (newLabel != nil && [newLabel length]) {
				[label setStringValue:newLabel];
			}			
		}
	} else {
		_shouldEndSession = YES;
	}
}

- (NSArray *) runControlFromOptions:(CDOptions *)options
{
	NSFileHandle *stdinFH;
	fd_set rfds;
	struct timeval tv;
	int selectRv;

	[self setOptions:options];
	
	// Load nib or return nil
	if (![NSBundle loadNibNamed:@"Progressbar" owner:self]) {
		if ([options hasOpt:@"debug"]) {
			[CDControl debug:@"Could not load Progressbar.nib"];
		}
		return nil;
	}
	
	// set text label
	if ([options optValue:@"text"]) {
		[label setStringValue:[options optValue:@"text"]];
	} else {
		[label setStringValue:@""];
	}
	
	// resize if necessary
	if ([self windowNeedsResize:panel]) {
		[panel setContentSize:[self findNewSizeForWindow:panel]];
	}
	
	[progressBar setMinValue:CDProgressbarMIN];
	[progressBar setMaxValue:CDProgressbarMAX];
	
	// set initial percent
	if ([options optValue:@"percent"]) {
		double initialPercent = [self _percentFromString:
			[options optValue:@"percent"]];
		[progressBar setDoubleValue:initialPercent];
	}
	
	//set window title
	if ([options optValue:@"title"]) {
		[panel setTitle:[options optValue:@"title"]];
	}

	// set indeterminate
	if ([options hasOpt:@"indeterminate"]) {
		[progressBar setIndeterminate:YES];
		[progressBar startAnimation:self];
	} else {
		[progressBar setIndeterminate:NO];
	}
	
	stdinFH = [NSFileHandle fileHandleWithStandardInput];
	_shouldEndSession = NO; // changed in _readData:

	// first run for half a second without showing the window
	int i;
	for (i = 0; i < 50; i++) {
		FD_ZERO(&rfds);
		FD_SET([stdinFH fileDescriptor], &rfds);
		tv.tv_sec = 0;
		tv.tv_usec = 100;
		selectRv = select(1, &rfds, NULL, NULL, &tv);
		if (selectRv) {
			[self _readData:[stdinFH availableData]];
		}

		if (_shouldEndSession) {
			FD_CLR([stdinFH fileDescriptor], &rfds);
			break;
		}
	}

	if(!_shouldEndSession) {
		NSModalSession session = [NSApp beginModalSessionForWindow:panel];
		for (;;) {
			FD_ZERO(&rfds);
			FD_SET([stdinFH fileDescriptor], &rfds);
			tv.tv_sec = 0;
			tv.tv_usec = 100;
			selectRv = select(1, &rfds, NULL, NULL, &tv);
			if (selectRv) {
				[self _readData:[stdinFH availableData]];
			}

			if ([NSApp runModalSession:session] != NSRunContinuesResponse)
				break;

			if ([options hasOpt:@"indeterminate"])
				[progressBar startAnimation:self];

			if (_shouldEndSession) {
				FD_CLR([stdinFH fileDescriptor], &rfds);
				break;
			}
		}
		[NSApp endModalSession:session];
	}

	return [NSArray array];
}

@end
