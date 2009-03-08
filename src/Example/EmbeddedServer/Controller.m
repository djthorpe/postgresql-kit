//
//  Controller.m
//  postgresql
//
//  Created by David Thorpe on 08/03/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"

@implementation Controller
@synthesize server;
@synthesize client;
@synthesize timer;

////////////////////////////////////////////////////////////////////////////////

-(void)dealloc {
	[self setTimer:nil];
	[self setClient:nil];
	[self setServer:nil];
	[super dealloc];
}

-(void)close {
	[[self timer] invalidate];
	[self setTimer:nil];
	[[self client] disconnect];
	[self setClient:nil];
	[[self server] stop];
	[self setServer:nil];	
}

-(void)awakeFromNib {
	// create the server object
	[self setServer:[FLXServer sharedServer]];
	NSParameterAssert([self server]);
	// create the client object
	[self setClient:[[[FLXPostgresConnection alloc] init] autorelease]];
	
	// set server delegate
	[[self server] setDelegate:self];
	
	// create the timer which will fire up the database
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];	
}

///////////////////////////////////////////////////////////////////////////////
// server: start and stop server

-(NSString* )_dataPath {
	NSArray* theIdent = [[[NSBundle mainBundle] bundleIdentifier] componentsSeparatedByString:@"."];
	NSArray* theApplicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theApplicationSupportDirectory count]);
	NSParameterAssert([theIdent count]);
	return [[theApplicationSupportDirectory objectAtIndex:0] stringByAppendingPathComponent:[theIdent objectAtIndex:([theIdent count]-1)]];
}

-(void)_startServer {
	// start the server
	
	// create application support path
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self _dataPath] isDirectory:&isDirectory]==NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath:[self _dataPath] attributes:nil];
	}
	
	// initialize the data directory if nesessary
	NSString* theDataDirectory = [[self _dataPath] stringByAppendingPathComponent:@"data"];
	if([[self server] startWithDataPath:theDataDirectory]==NO) {
		// starting failed, possibly because a server is already running
		if([[self server] state]==FLXServerStateAlreadyRunning) {
			[[self server] stop];
		}
	}    	
}

-(void)_stopServer {
	[[self server] stop];
}

///////////////////////////////////////////////////////////////////////////////
// client: connect and disconnect from server

-(void)_connectToServer {
	NSParameterAssert([[self client] connected]==NO);
	[[self client] setPort:9001];
	[[self client] setDatabase:[FLXServer superUsername]];
	[[self client] connect];
	NSParameterAssert([[self client] connected]);
	NSParameterAssert([[self client] database]);
	NSParameterAssert([[[self client] database] isEqual:[FLXServer superUsername]]);
}

-(void)_disconnectFromServer {
	[[self client] disconnect];
}

-(void)_selectDatabase:(NSString* )theDatabase {
	NSParameterAssert([[self client] connected]);
	[[self client] disconnect];
	[[self client] setDatabase:theDatabase];
	[[self client] connect];
	NSParameterAssert([[self client] connected]);
}

////////////////////////////////////////////////////////////////////////////////

-(void)timerDidFire:(id)sender {	
	if([[self server] isRunning]==NO) {
		NSLog(@"starting server....");
		[self _startServer];
	} else {		
		NSLog(@"timer did fire, server state = %d",[[self server] state]);
	}
}

////////////////////////////////////////////////////////////////////////////////
// FLXServer delegate messages

-(void)serverMessage:(NSString* )theMessage {
	NSLog(@"server message: %@",theMessage);
}

-(void)serverStateDidChange:(NSString* )theMessage {
	NSLog(@"server state did change: %@",theMessage);
}

@end
