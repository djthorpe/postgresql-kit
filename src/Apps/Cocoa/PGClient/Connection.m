
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

#import "Connection.h"

@implementation Connection

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [PGConnectionWindowController new];
		NSParameterAssert(_connection);
		// set delegate
		[_connection setDelegate:self];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize parentWindow;
@synthesize connection = _connection;
@dynamic url;

-(NSURL* )url {
	return [NSURL URLWithString:@"postgres://pttnkktdoyjfyc@ec2-54-227-255-156.compute-1.amazonaws.com:5432/dej7aj0jp668p5"];
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)loginSheetWithWindow:(NSWindow* )window {
	NSParameterAssert(window);

	// set default URL
	[[self connection] setUrl:[self url]];
	// set window property
	[self setParentWindow:window];
	// begin sheet
	[[self connection] beginSheetForParentWindow:window];
}

-(void)disconnect {
	[[self connection] disconnect];
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionWindowDelegate

-(void)connectionWindow:(PGConnectionWindowController* )windowController status:(PGConnectionWindowStatus)status {
	switch(status) {
		case PGConnectionWindowStatusOK:
			[windowController connect];
			break;
		case PGConnectionWindowStatusNeedsPassword:
			[[self connection] beginPasswordSheetForParentWindow:[self parentWindow]];
			break;
		case PGConnectionWindowStatusCancel:
			NSLog(@"PGConnectionWindow sent status CANCEL PRESSED");
			break;
		case PGConnectionWindowStatusConnecting:
			NSLog(@"PGConnectionWindow sent status CONNECTING");
			break;
		case PGConnectionWindowStatusBadParameters:
			NSLog(@"PGConnectionWindow sent status BAD PARAMETERS");
			//[[self connection] beginErrorSheetForParentWindow:[self parentWindow]];
			break;
		case PGConnectionWindowStatusRejected:
			NSLog(@"PGConnectionWindow sent status REJECTED CONNECTION");
			[[self connection] beginErrorSheetForParentWindow:[self parentWindow]];
			break;
		case PGConnectionWindowStatusConnected:
			NSLog(@"PGConnectionWindow sent status CONNECTED");
			break;
	}
}

-(void)connectionWindow:(PGConnectionWindowController *)windowController error:(NSError* )error {
	NSLog(@"error = %@",error);
}

@end
