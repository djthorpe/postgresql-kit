
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

#import "PGSourceViewTree.h"

@implementation PGSourceViewTree

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if(self) {
		_tags = [NSMutableDictionary new];
		_children = [NSMutableDictionary new];
		_counter = 0;
		NSParameterAssert(_tags && _children);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic count;

-(NSUInteger)count {
	return [_tags count];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(id)_keyForTag:(NSInteger)tag {
	return [NSNumber numberWithInteger:tag];
}

-(id)_rootKey {
	return @0;
}

-(PGSourceViewNode* )_nodeForTagKey:(id)key {
	NSParameterAssert(key);
	return [_tags objectForKey:key];
}

-(id)_tagKeyForNode:(PGSourceViewNode* )node {
	NSArray* keys = [_tags allKeysForObject:node];
	if([keys count]) {
		NSParameterAssert([keys count]==1);
		return [keys objectAtIndex:0];
	} else {
		return nil;
	}
}

-(id)_getNewTagKey {
	do {
		NSInteger tag = ++_counter;
		id key = [self _keyForTag:tag];
		if([self _nodeForTagKey:key]==nil) {
			// no existing tag
			return key;
		}
	} while(_counter <= NSIntegerMax);
	return nil;
}

-(id)_addNode:(PGSourceViewNode* )node tag:(NSInteger)tag {
	NSParameterAssert(node);
	id key = tag ? [self _keyForTag:tag] : [self _getNewTagKey];
	if(key && [self _nodeForTagKey:key]) {
		// object already exists with this tag key
		return nil;
	}
	if(key) {
		// add object
		[_tags setObject:node forKey:key];
	}
	return key;
}

-(NSMutableArray* )_childrenForKey:(id)key {
	return [_children objectForKey:((key==nil) ? [self _rootKey] : key)];
}

-(void)_addChildKey:(id)key parentKey:(id)parentKey index:(NSInteger)index {
	// TODO: check key is not there yet
	NSMutableArray* children = [self _childrenForKey:parentKey];
	if(children==nil) {
		children = [NSMutableArray new];
		NSParameterAssert(children);
		[_children setObject:children forKey:(parentKey ? parentKey : [self _rootKey])];
	}
	if(index==-1) {
		// add at the end
		[children addObject:key];
	} else {
		[children insertObject:key atIndex:index];
	}
}

-(NSInteger)_tagForKey:(id)key {
	if(key==nil) {
		return 0;
	}
	if([key isKindOfClass:[NSNumber class]]==NO) {
		return 0;
	}
	return [(NSNumber* )key integerValue];
}

-(void)_removeNodeWithKey:(id)key {
	NSParameterAssert(key);
	NSArray* children = [self _childrenForKey:key];
	for(id childKey in children) {
		[self _removeNodeWithKey:childKey];
	}
	[_children removeObjectForKey:key];
	[_tags removeObjectForKey:key];
	for(id parentKey in _children) {
		NSMutableArray* children = [self _childrenForKey:parentKey];
		[children removeObject:key];
	}
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent {
	return [self addNode:node parent:parent tag:0];
}

-(NSInteger)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent tag:(NSInteger)tag {
	// ensure parent is in the tree, and node isn't
	NSParameterAssert(parent==nil || [self _tagKeyForNode:parent]);
	NSParameterAssert(node && [self _tagKeyForNode:node]==nil);
	// if parent is nil, tag must be zero
	//NSParameterAssert(parent==nil || tag != 0);
	id key = [self _addNode:node tag:tag];
	if(key) {
		[self _addChildKey:key parentKey:[self _tagKeyForNode:parent] index:-1];
	}
	return [self _tagForKey:key];
}


-(BOOL)moveNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent index:(NSInteger)index {
	NSParameterAssert(node);
	id key = [self _tagKeyForNode:node];
	if(key==nil) {
		// return NO if node is not already in the tree or is the root tag
		return NO;
	}
	// remove node from all children
	for(id parentKey in _children) {
		NSMutableArray* children = [self _childrenForKey:parentKey];
		[children removeObject:key];
	}
	// get children of parent
	id newParentKey = parent ? [self _tagKeyForNode:parent] : [self _rootKey];
	NSParameterAssert(newParentKey);
	[self _addChildKey:key parentKey:newParentKey index:index];
	return YES;
}

-(NSInteger)tagForNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	id key = [self _tagKeyForNode:node];
	if(key) {
		return [self _tagForKey:key];
	}
	return 0;
}

-(void)removeAllNodes {
	[_tags removeAllObjects];
	[_children removeAllObjects];
	_counter = 0;
}

-(void)removeNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	id key = [self _tagKeyForNode:node];
	NSParameterAssert(key);
	[self _removeNodeWithKey:key];
}

-(PGSourceViewNode* )nodeAtIndex:(NSInteger)index parent:(PGSourceViewNode* )parent {
	id key = parent ? [self _tagKeyForNode:parent] : [self _rootKey];
	if(key==nil) {
		// parent not found, return nil
		return nil;
	}
	NSArray* children = [self _childrenForKey:key];
	NSParameterAssert(children);
	NSParameterAssert(index >= 0 && index < [children count]);
	PGSourceViewNode* node = [self _nodeForTagKey:[children objectAtIndex:index]];
	NSParameterAssert(node);
	return node;
}

-(NSInteger)numberOfChildrenOfParent:(PGSourceViewNode* )parent {
	id key = parent ? [self _tagKeyForNode:parent] : [self _rootKey];
	if(key==nil) {
		// parent not found, return nil
		return NSNotFound;
	}
	return [[self _childrenForKey:key] count];
}

-(PGSourceViewNode* )nodeForTag:(NSInteger)tag {
	NSParameterAssert(tag);
	return [self _nodeForTagKey:[self _keyForTag:tag]];
}

////////////////////////////////////////////////////////////////////////////////
// public methods - NSUserDefaults

-(BOOL)loadFromUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSArray* nodes = [defaults arrayForKey:@"nodes"];
	NSDictionary* children = [defaults dictionaryForKey:@"children"];
	if([nodes count]==0 || [children count]==0) {
		return NO;
	}
	
	// remove existing data
	[self removeAllNodes];
	
	// add in the nodes
	for(NSDictionary* data in nodes) {
		if([data isKindOfClass:[NSDictionary class]]==NO) {
			continue;
		}
		PGSourceViewNode* node = [PGSourceViewNode nodeFromDictionary:data];
		if(node==nil) {
			continue;
		}
		NSNumber* tag = [data objectForKey:@"key"];
		if([tag isKindOfClass:[NSNumber class]]==NO) {
			continue;
		}
		[_tags setObject:node forKey:tag];
	}
	
	// add the children
	for(NSString* keystring in children) {
		NSInteger tag = [keystring integerValue];
		id key = [self _keyForTag:tag];
		if(tag) {
			if([self _nodeForTagKey:key]==nil) {
#ifdef DEBUG
				NSLog(@"loadFromUserDefaults: warning: ignoring key %@ from nodes %@",key,_tags);
#endif
				continue;
			}
		}
		
		NSArray* childkeys = [children objectForKey:keystring];
		NSParameterAssert(childkeys);
		NSMutableArray* childkeyscopy = [NSMutableArray arrayWithCapacity:[childkeys count]];
		for(NSNumber* childkey in childkeys) {
			if([self _nodeForTagKey:childkey]==nil) {
#ifdef DEBUG
				NSLog(@"loadFromUserDefaults: warning: ignoring child key %@ of parent %@",childkey,key);
#endif
				continue;
			}
			[childkeyscopy addObject:childkey];
		}
		[_children setObject:childkeyscopy forKey:key];
	}
	return YES;
}

-(BOOL)saveToUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	// get nodes
	NSMutableArray* nodes = [NSMutableArray arrayWithCapacity:[_tags count]];
	NSParameterAssert(nodes);
	for(id key in _tags) {
		PGSourceViewNode* node = [self _nodeForTagKey:key];
		NSParameterAssert(node);
		[nodes addObject:[node dictionaryWithKey:key]];
	}

	NSMutableDictionary* children = [NSMutableDictionary dictionaryWithCapacity:[_children count]];
	NSParameterAssert(children);
	for(NSNumber* key in _children) {
		NSParameterAssert([key isKindOfClass:[NSNumber class]]);
		[children setObject:[_children objectForKey:key] forKey:[key description]];
	}
	
	// save nodes and children in defaults
	[defaults setObject:nodes forKey:@"nodes"];
	[defaults setObject:children forKey:@"children"];

	// synchronize to disk
	return [defaults synchronize];
}

@end
