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
		m_theChildren = [[NSMutableArray alloc] init];
	}
	return self;
}

-(id)initWithName:(NSString* )theName {
	self = [super init];
	if (self != nil) {
		m_theName = [theName retain];
		m_theChildren = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc {
	[m_theName release];
	[m_theChildren release];
	[super dealloc];
}

+(OutlineNode* )nodeWithName:(NSString* )theName {
	return [[[OutlineNode alloc] initWithName:theName] autorelease];
}

-(NSMutableArray* )children {
	return m_theChildren;
}

-(NSString* )name {
	return m_theName;
}

-(NSString* )description {
	return [self name];
}

@end
