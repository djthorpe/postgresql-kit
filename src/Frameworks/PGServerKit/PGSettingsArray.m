
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

@implementation PGSettingsArray

////////////////////////////////////////////////////////////////////////////////
#pragma mark Constructor
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
    self = [super init];
    if (self) {
        _array = [NSMutableArray array];
		NSParameterAssert(_array);
    }
    return self;
}

-(instancetype)initWithData:(NSData* )data {
	NSParameterAssert(data);
	self = [super init];
	if(self) {
		_array = [[self _parseData:data encoding:NSUTF8StringEncoding] mutableCopy];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////

@dynamic count;
@dynamic data;
@dynamic rules;

-(NSUInteger)count {
	return [_array count];
}

-(NSData* )data {
	return [self dataWithEncoding:NSUTF8StringEncoding];
}

-(NSArray* )rules {
	return _array;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////

-(NSData* )dataWithEncoding:(NSStringEncoding)encoding {
	NSMutableData* data = [NSMutableData new];
	if([_array count]==0) {
		return data;
	}
	for(PGHostAccessRule* rule in _array) {
		[data appendData:[rule dataWithEncoding:encoding]];
	}
	return data;
}

-(NSArray* )_parseData:(NSData* )data encoding:(NSStringEncoding)encoding {
	NSParameterAssert(data);
	NSString* textFile = [[NSString alloc] initWithData:data encoding:encoding];
	if([textFile length]==0) {
		return nil;
	}

	// parse lines into an array of rules
	NSMutableArray* rules = [NSMutableArray new];
	NSParameterAssert(rules);
	
	// TODO: Write parser here

	return rules;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Public Methods
////////////////////////////////////////////////////////////////////////////////

-(PGSettingsRule* )ruleAtIndex:(NSUInteger)index {
	return [_array objectAtIndex:index];
}

-(void)addRule:(PGSettingsRule* )rule {
	NSParameterAssert(rule);
	[_array addObject:rule];
}

@end
