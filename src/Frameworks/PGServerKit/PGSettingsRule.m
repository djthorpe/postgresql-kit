
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

#import <PGServerKit/PGServerKit.h>

enum {
	PGSettingsRuleStateInit = 0,
	PGSettingsRuleStateComment = 1,
	PGSettingsRuleStateSetting = 2
};

@implementation PGSettingsRule

////////////////////////////////////////////////////////////////////////////////
#pragma mark Construcor
////////////////////////////////////////////////////////////////////////////////

-(instancetype)initWithString:(NSString* )string {
	NSParameterAssert(string);
    self = [super init];
    if (self) {
		_state = PGSettingsRuleStateInit;
		_key = nil;
		_value = nil;
        _comment = nil;
		if([self _parseString:string]==NO) {
			return nil;
		}
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@synthesize key = _key;
@synthesize value = _value;
@synthesize comment = _comment;

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////

-(BOOL)_parseString:(NSString* )string {
	NSString* line = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	// find out if this is a straight comment line, or a setting line
	NSArray* tokens = [[self class] _tokensFromString:line];
	NSLog(@"TODO: Parse %@",tokens);
	return YES;
}

+(NSArray* )_tokensFromString:(NSString* )string {
	NSScanner* theScanner = [NSScanner scannerWithString:string];
	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"=#"];
//	NSMutableCharacterSet* tokenCharactersSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"='\"#"];
	[tokenCharactersSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
	NSMutableArray* tokens = [NSMutableArray new];
	BOOL insideQuotes = NO;
	BOOL isAtEnd = NO;
	NSString* tempString;
	NSMutableString* currentToken = [NSMutableString string];
	[theScanner setCharactersToBeSkipped:nil];
    while([theScanner isAtEnd]==NO) {
		// chew up next bit of the token
		if([theScanner scanUpToCharactersFromSet:tokenCharactersSet intoString:&tempString]) {
			[currentToken appendString:tempString];
			continue;
		}
		// equals signs, hash
		if([theScanner scanString:@"=" intoString:&tempString] || [theScanner scanString:@"#" intoString:&tempString]) {
			if(insideQuotes) {
				[currentToken appendString:tempString];
			} else {
				if([currentToken length]) {
					[tokens addObject:[currentToken copy]];
					[currentToken setString:@""];
				}
				[tokens addObject:[tempString copy]];
			}
			continue;
		}
		// whitespace
		if([theScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&tempString]) {
			if(insideQuotes) {
				[currentToken appendString:tempString];
			} else {
				if([currentToken length]) {
					[tokens addObject:[currentToken copy]];
					[currentToken setString:@""];
				}
				[tokens addObject:[tempString copy]];
			}
			continue;
		}
	}
	if([currentToken length]) {
		[tokens addObject:[currentToken copy]];
	}
	
	return tokens;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Public Methods
////////////////////////////////////////////////////////////////////////////////

-(BOOL)appendString:(NSString* )string {
	return [self _parseString:string];
}

-(NSData* )dataWithEncoding:(NSStringEncoding)encoding {
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark NSObject Overrides
////////////////////////////////////////////////////////////////////////////////

@end
