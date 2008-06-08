//
//  OutlineNode.m
//  postgresql
//
//  Created by David Thorpe on 08/06/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OutlineNode.h"
#import "main.h"

@implementation OutlineNode

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theName = nil;
		m_theType = nil;
		m_theChildren = [[NSMutableArray alloc] init];
	}
	return self;
}

-(id)initWithName:(NSString* )theName type:(NSString* )theType {
	self = [super init];
	if (self != nil) {
		m_theName = [theName retain];
		m_theType = [theType retain];
		m_theChildren = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc {
	[m_theName release];
	[m_theType release];
	[m_theChildren release];
	[super dealloc];
}

+(OutlineNode* )rootNodeWithName:(NSString* )theName {
	return [[[OutlineNode alloc] initWithName:theName type:FLXNodeRoot] autorelease];	
}

+(OutlineNode* )schemaNodeWithName:(NSString* )theName {
	return [[[OutlineNode alloc] initWithName:theName type:FLXNodeSchema] autorelease];	
}

+(OutlineNode* )schemaNodeAll {
	return [[[OutlineNode alloc] initWithName:@"All" type:FLXNodeSchemaAll] autorelease];
}

+(OutlineNode* )tableNodeWithName:(NSString* )theName {
	return [[[OutlineNode alloc] initWithName:theName type:FLXNodeTable] autorelease];
}

+(OutlineNode* )queryNodeWithName:(NSString* )theName {
	return [[[OutlineNode alloc] initWithName:theName type:FLXNodeQuery] autorelease];	
}

-(NSMutableArray* )children {
	return m_theChildren;
}

-(void)setChildren:(NSMutableArray* )theChildren {
	[theChildren retain];
	[m_theChildren release];
	m_theChildren = theChildren;
}

-(NSString* )name {
	return m_theName;
}

-(BOOL)isRootNode {
	return [m_theType isEqual:FLXNodeRoot];
}

-(BOOL)isSchemaNode {
	return [m_theType isEqual:FLXNodeSchema] || [m_theType isEqual:FLXNodeSchemaAll];	
}

-(BOOL)isSchemaAllNode {
	return [m_theType isEqual:FLXNodeSchemaAll];
}

-(BOOL)isTableNode {
	return [m_theType isEqual:FLXNodeTable];
}

-(BOOL)isQueryNode {
	return [m_theType isEqual:FLXNodeQuery];
}

-(NSString* )description {
	return [NSString stringWithFormat:@"%@:%@",m_theType,[self name]];
}

@end
