//
//  Bindings.m
//  postgresql
//
//  Created by David Thorpe on 08/03/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Bindings.h"

@implementation Bindings
@synthesize output;
@synthesize input;
@synthesize isInputEnabled;

-(id)init {
	self = [super init];
	if (self != nil) {
		[self setOutput:[NSString string]];
		[self setInput:[NSString string]];
		[self setIsInputEnabled:NO];
	}
	return self;
}

-(void)dealloc {
	[self setOutput:nil];
	[self setInput:nil];
	[super dealloc];
}

@end
