
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <PGClientKit/PGClientKit.h>
#import "PGConnectionWindowFormatter.h"

@implementation PGConnectionWindowFormatter

////////////////////////////////////////////////////////////////////////////////
// constructor

-(void)awakeFromNib {
	if(!_cs) {
		_cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
	}
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize type;

////////////////////////////////////////////////////////////////////////////////
// methods

-(NSNumber* )numericValueForString:(NSString* )string {
	NSParameterAssert(_cs);
	if([string length]==0) {
		return nil;
	}
	NSString* string2 = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSRange range = [string2 rangeOfCharacterFromSet:_cs];
	if(range.location != NSNotFound) {
		return nil;
	}
	NSNumber* number = [NSDecimalNumber decimalNumberWithString:string];
	if([number unsignedIntegerValue] < 1 || [number unsignedIntegerValue] > 65535) {
		return nil;
	}
	return number;
}


-(NSString* )stringForObjectValue:(id)anObject {
	return [NSString stringWithFormat:@"%@",anObject];
}

-(BOOL)getObjectValue:(id* )anObject forString:(NSString* )string errorDescription:(NSString** )anError {
	NSParameterAssert(anObject);
	NSParameterAssert(string);

	BOOL returnValue = YES;
	NSString* theError = nil;
	if([[self type] isEqualTo:@"port"]) {
		NSNumber* port = [self numericValueForString:string];
		if(port==nil) {
			theError = @"Invalid value, requires numeric value";
			returnValue = NO;
		} else {
			*anObject = port;
		}
	} else if([[self type] isEqualTo:@"host"]) {
		if([string isNetworkHostname] || [string isNetworkAddress]) {
			*anObject = string;
		} else {
			theError = @"Invalid value";
			returnValue = NO;
		}
	}
	if(anError && theError) {
		*anError = theError;
	}
	return returnValue;
}
@end
