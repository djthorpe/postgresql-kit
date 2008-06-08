//
//  OutlineNode.m
//  postgresql
//
//  Created by David Thorpe on 08/06/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OutlineNode.h"

@implementation OutlineNode

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theName = nil;
	}
	return self;
}

-(id)initWithName:(NSString* )theName {
	self = [super init];
	if (self != nil) {
		m_theName = [theName retain];
	}
	return self;
}

-(void)dealloc {
	[m_theName release];
	[super dealloc];
}

+(OutlineNode* )nodeWithName:(NSString* )theName {
	return [[[OutlineNode alloc] initWithName:theName] autorelease];
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<OutlineNode: %@>",m_theName];
}

@end
