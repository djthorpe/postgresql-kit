
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

#import <PGControlsKit/PGControlsKit.h>

@implementation PGConsoleViewBuffer

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_rows = [NSMutableArray new];
		NSParameterAssert(_rows);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)appendString:(NSString* )string textColor:(NSColor* )color {
	NSParameterAssert(string);
	[_rows addObject:string];
}

-(void)appendString:(NSString* )string {
	[self appendString:string textColor:nil];
}

////////////////////////////////////////////////////////////////////////////////
// PGConsoleViewDataSource implementation

-(NSUInteger)numberOfRowsForConsoleView:(PGConsoleViewController* )view {
	return [_rows count];
}

-(NSString* )consoleView:(PGConsoleViewController* )consoleView stringForRow:(NSUInteger)row {
	NSParameterAssert(row >= 0 && row < [_rows count]);
	NSString* string = [_rows objectAtIndex:row];
	NSParameterAssert([string isKindOfClass:[NSString class]]);
	return string;
}

@end
