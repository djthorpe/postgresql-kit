
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
@dynamic tag;

-(NSURL* )url {
	return [NSURL URLWithString:@"postgres://pttnkktdoyjfyc@ec2-54-227-255-156.compute-1.amazonaws.com:5432/dej7aj0jp668p5"];
}

-(NSInteger)tag {
	return [[self connection] tag];
}

-(void)setTag:(NSInteger)value {
	[[self connection] setTag:value];
}

////////////////////////////////////////////////////////////////////////////////
// private methods


////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)loginSheetWithWindow:(NSWindow* )window {
	NSParameterAssert(window);

	// disconnect
	[self disconnect];

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

-(void)doubleClickedNode:(PGSourceViewConnection* )node {
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);
	
	if([node URL]) {
		NSLog(@"double clicked node %@",[node URL]);
		[[self connection] setUrl:[node URL]];
		[[self connection] connect];
	}
	
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
		case PGConnectionWindowStatusRetry:
			[[self connection] beginSheetForParentWindow:[self parentWindow]];
			break;
		case PGConnectionWindowStatusRejected:
		case PGConnectionWindowStatusBadParameters:
			[[self connection] beginErrorSheetForParentWindow:[self parentWindow]];
			break;
		case PGConnectionWindowStatusCancel:
			if([[self delegate] respondsToSelector:@selector(connection:status:url:)]) {
				[[self delegate] connection:self status:ConnectionStatusCancelled url:[[self connection] url]];
			}
			break;
		case PGConnectionWindowStatusConnecting:
			if([[self delegate] respondsToSelector:@selector(connection:status:url:)]) {
				[[self delegate] connection:self status:ConnectionStatusConnecting url:[[self connection] url]];
			}
			break;
		case PGConnectionWindowStatusConnected:
			if([[self delegate] respondsToSelector:@selector(connection:status:url:)]) {
				[[self delegate] connection:self status:ConnectionStatusConnected url:[[self connection] url]];
			}
			break;
	}
}

-(void)connectionWindow:(PGConnectionWindowController *)windowController error:(NSError* )error {
	if([[self delegate] respondsToSelector:@selector(connection:error:)]) {
		[[self delegate] connection:self error:error];
	}
}

@end
