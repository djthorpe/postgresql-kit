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
@synthesize timer;

////////////////////////////////////////////////////////////////////////////////

-(void)dealloc {
	[[self timer] invalidate];
	[self setTimer:nil];
	[[self server] stop];
	[self setServer:nil];
	[super dealloc];
}

-(void)awakeFromNib {
	// create the server object
	[self setServer:[FLXServer sharedServer]];
	NSParameterAssert([self server]);
	
	// create the timer which will fire up the database
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES]];	
}

////////////////////////////////////////////////////////////////////////////////

-(void)timerDidFire:(id)sender {	
	NSLog(@"timer did fire, server state = %@",[[self server] serverStateAsString]);
}

@end
