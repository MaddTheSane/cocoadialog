/*
	CDFileSaveControl.m
	CocoaDialog
	Copyright (C) 2004-2006 Mark A. Stratman <mark@sporkstorms.org>
 
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

#import "CDFileSaveControl.h"


@implementation CDFileSaveControl

- (NSDictionary *) availableKeys
{
	NSNumber *vMul = @(CDOptionsMultipleValues);
	NSNumber *vOne = @(CDOptionsOneValue);
	NSNumber *vNone = @(CDOptionsNoValues);

	return @{@"text": vOne,
			 @"with-extensions": vMul,
			 @"with-directory": vOne,
			 @"with-file": vOne,
			 @"packages-as-directories": vNone,
			 @"no-create-directories": vNone
			 };
}

- (NSArray *) runControlFromOptions:(CDOptions *)options
{
	NSInteger result;
	NSSavePanel *panel = [NSSavePanel savePanel];
	NSString *file = @"";
	
	[self setOptions:options];
	[self setMisc:panel];

	NSArray *extensions = [self extensionsFromOptionKey:@"with-extensions"];
	[panel setAllowedFileTypes:extensions];

	if ([options hasOpt:@"packages-as-directories"]) {
		[panel setTreatsFilePackagesAsDirectories:YES];
	} else {
		[panel setTreatsFilePackagesAsDirectories:NO];
	}

	if ([options hasOpt:@"no-create-directories"]) {
		[panel setCanCreateDirectories:NO];
	} else {
		[panel setCanCreateDirectories:YES];
	}

	// set starting file (to be used later with 
	// runModal...) - doesn't work.
	if ([options optValue:@"with-file"] != nil) {
		file = [options optValue:@"with-file"];
		panel.nameFieldStringValue = file;
	}
	// set starting directory (to be used later with runModal...)
	if ([options optValue:@"with-directory"] != nil) {
		NSString *dir = [options optValue:@"with-directory"];
		panel.directoryURL = [NSURL fileURLWithPath:dir];
	}

	// resize window if user specified alternate width/height
	if ([self windowNeedsResize:panel]) {
		[panel setContentSize:[self findNewSizeForWindow:panel]];
	}
	
	result = [panel runModal];

	if (result == NSFileHandlingPanelOKButton) {
		return [NSArray arrayWithObject:[panel URL].path];
	} else {
		return [NSArray array];
	}
}

@end
