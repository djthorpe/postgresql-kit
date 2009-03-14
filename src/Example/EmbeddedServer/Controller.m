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
@synthesize bindings;

////////////////////////////////////////////////////////////////////////////////

-(void)dealloc {
	[self setClient:nil];
	[self setServer:nil];
	[self setBindings:nil];	
	[super dealloc];
}

-(void)close {
	[[self client] disconnect];
	[[self server] stop];
	[self setClient:nil];
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
	
	// key-value observing
	[bindings addObserver:self forKeyPath:@"input" options:NSKeyValueObservingOptionNew context:nil];
	[bindings addObserver:self forKeyPath:@"output" options:NSKeyValueObservingOptionNew context:nil];
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
// execute command when input

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	if([keyPath isEqualTo:@"input"] && [bindings input]) {
		//[self serverMessage:[bindings input]];
		//[bindings setInput:nil];
		NSLog(@"input changed");
	}
	if([keyPath isEqualTo:@"output"]) {
		// output changed
		NSLog(@"output changed");
	}
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
// IBAction

-(IBAction)doStartServer:(id)sender {
	if([[self server] isRunning]==NO) {
		[self _startServer];
	}
}

-(IBAction)doStopServer:(id)sender {
	if([[self server] isRunning]==YES) {
		[self _stopServer];
	} 		
}

-(IBAction)doBackupServer:(id)sender {
	NSLog(@"TODO: backup server");
}

////////////////////////////////////////////////////////////////////////////////
// FLXServer delegate messages

-(void)serverMessage:(NSString* )theMessage {
	NSMutableAttributedString* theAttributedMessage = [[[NSMutableAttributedString alloc] init] autorelease];
	if([bindings output]) {
		[theAttributedMessage appendAttributedString:[bindings output]];
	}
	[theAttributedMessage replaceCharactersInRange:NSMakeRange([theAttributedMessage length],0) withString:theMessage];
	[theAttributedMessage replaceCharactersInRange:NSMakeRange([theAttributedMessage length],0) withString:@"\n"];
	[bindings setOutput:theAttributedMessage];
}

-(void)serverStateDidChange:(NSString* )theMessage {
	// output message
	[self serverMessage:[NSString stringWithFormat:@"Server state: %@",theMessage]];
	
	// only enable the input when server status is running
	[bindings setIsInputEnabled:([[self server] state]==FLXServerStateStarted) ? YES : NO];
}

@end
