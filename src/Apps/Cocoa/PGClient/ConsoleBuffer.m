
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

#import "ConsoleBuffer.h"

@implementation ConsoleBuffer

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_buffers = [NSMutableDictionary new];
		NSParameterAssert(_buffers);
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////
// private methods

+(id)keyForTag:(NSInteger)tag {
	return [NSNumber numberWithInteger:tag];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(PGConsoleViewBuffer* )bufferForTag:(NSInteger)tag {
	id key = [ConsoleBuffer keyForTag:tag];
	NSParameterAssert(key);
	PGConsoleViewBuffer* buffer = [_buffers objectForKey:key];
	if(buffer==nil) {
		return nil;
	}
	NSParameterAssert([buffer isKindOfClass:[PGConsoleViewBuffer class]]);
	return buffer;
}

-(void)setBuffer:(PGConsoleViewBuffer* )buffer forTag:(NSInteger)tag {
	NSParameterAssert(buffer);
	id key = [ConsoleBuffer keyForTag:tag];
	NSParameterAssert(key);
	[_buffers setObject:buffer forKey:key];
}

-(void)removeAll {
	[_buffers removeAllObjects];
}

-(void)appendString:(NSString* )string forTag:(NSInteger)tag {
	NSParameterAssert(string);
	id key = [ConsoleBuffer keyForTag:tag];
	NSParameterAssert(key);
	PGConsoleViewBuffer* buffer = [_buffers objectForKey:key];
	NSParameterAssert(buffer);
	[buffer appendString:string];
}

@end
