/*
	CDOptions.m
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

#import "CDOptions.h"


@implementation CDOptions

- initWithOpts:(NSMutableDictionary *)opts
{
	self = [super init];
	_options = opts;
	return self;
}
- init
{
	return [self initWithOpts:[NSMutableDictionary dictionary]];
}

+ (BOOL) _argIsKey:(NSString *)arg availableKeys:(NSDictionary *)availableKeys
{
	if ([arg length] > 2
	    && [[arg substringWithRange:NSMakeRange(0,2)] isEqualToString:@"--"]
	    && [availableKeys objectForKey:[arg substringFromIndex:2]] != nil)
	{
		return YES;
	} else {
		return NO;
	}
}

+ (CDOptions *) getOpts:(NSArray *)args 
		  availableKeys:(NSDictionary *)availableKeys
{
	NSMutableDictionary *options;
	NSString *arg;
	NSMutableArray *values;
	int i;
	int argType;

	options = [NSMutableDictionary dictionaryWithCapacity:8];

	i = 0;
	while (i < [args count]) {
		arg = [args objectAtIndex:i];

		// If the arg is a key we specified above...
		if ([CDOptions _argIsKey:arg availableKeys:availableKeys]) {
			// strip leading '--'
			arg = [arg substringFromIndex:2];
			argType = [[availableKeys objectForKey:arg] intValue];

			// If it's a no-value option, store the bool NO to indicate
			// no values for this key, increment i and continue.
			if (argType == CDOptionsNoValues) {
				[options setObject:[NSNumber numberWithBool:NO] forKey:arg];
				i++;
				continue;
			}
			// Control reaches here there should be one or more
			// values for key.
			values = [NSMutableArray arrayWithCapacity:8];
			while (i+1 < [args count] &&
			       ! [CDOptions _argIsKey:[args objectAtIndex:i+1] 
					availableKeys:availableKeys])
			{
				NSString *nextArg = [args objectAtIndex:i+1];

				// set single string value for this key,
				// increment i and stop looking for more values
				if (argType == CDOptionsOneValue) {
					[options setObject:nextArg
						    forKey:arg];
					i++;
					break;
				// add a value to the values array
				} else if (argType == CDOptionsMultipleValues) {
					[values addObject:nextArg];
					i++;
					
				// Programmer supplied an invalid type for this
				// available key.
				} else {
					break;
				}
			} // End looking for more values to to a key

			// set the array of values for this key
			if (argType == CDOptionsMultipleValues) {
				[options setObject:values forKey:arg];
			}
		} // End "if arg was a key"
		i++;
	} // End processing all args

	return [[CDOptions alloc] initWithOpts:options];
}

+ (void) printOpts:(NSDictionary *)availableKeys
{
	NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];

	if (fh) {
		[fh writeData:[@"All Available options:\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	NSEnumerator *enumerator = [availableKeys keyEnumerator];
	for (id key in enumerator) {
		[fh writeData:[@"\t--" dataUsingEncoding:NSUTF8StringEncoding]];
		[fh writeData:[key dataUsingEncoding:NSUTF8StringEncoding]];
		[fh writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

- (BOOL) hasOpt:(NSString *)key
{
	return [_options objectForKey:key] != nil;
}
- (NSString *) optValue:(NSString *)key
{
	id value = [_options objectForKey:key];
	// value will be an NSNumber (set in getOpts) if there is no value
	// for that key, NSString of the value, or nil if that key didn't exist
	if (value == nil || ![value isKindOfClass:[NSString class]]) {
		return nil;
	} else {
		return value;
	}
}
- (NSArray *) optValues:(NSString *)key
{
	id value = [_options objectForKey:key];
	if (value == nil || ![value isKindOfClass:[NSArray class]]) {
		return nil;
	} else {
		return value;
	}
}
- (id) optValueOrValues:(NSString *)key
{
	return [_options objectForKey:key];
}


- (NSArray *) allOptions    { return [_options allKeys]; }
- (NSArray *) allOptValues  { return [_options allValues]; }

- (void) setOption:(id)value forKey:(NSString *)key
{
	[_options setObject:value forKey:key];
}

@end
