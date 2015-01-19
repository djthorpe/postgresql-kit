
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
// private methods

-(id)keyForTag:(NSInteger)tag {
	return [NSNumber numberWithInteger:tag];
}

-(id)rootKey {
	return @0;
}

-(PGSourceViewNode* )nodeForTagKey:(id)key {
	NSParameterAssert(key);
	return [_tags objectForKey:key];
}

-(id)tagKeyForNode:(PGSourceViewNode* )node {
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
		NSInteger tag = _counter++;
		id key = [self keyForTag:tag];
		if([self nodeForTagKey:key]==nil) {
			// no existing tag
			return key;
		}
	} while(_counter <= NSIntegerMax);
	return nil;
}

-(id)_addNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	id key = [self _getNewTagKey];
	if(key) {
		[_tags setObject:node forKey:key];
		[_children setObject:[NSMutableArray new] forKey:key];
	}
	return key;
}

-(void)_addChildKey:(id)key parentKey:(id)parentKey {
	NSMutableArray* array = [_children objectForKey:(parentKey ? parentKey : [self rootKey])];
	NSParameterAssert(array);
	[array addObject:key];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent {
	// ensure parent is in the tree, and node isn't
	NSParameterAssert(parent==nil || [self tagKeyForNode:parent]);
	NSParameterAssert(node && [self tagKeyForNode:node]==nil);
	// if parent==nil, than use tag 0 or else determine tag for this node
	id key = [self _addNode:node];
	NSParameterAssert(key);
	[self _addChildKey:key parentKey:[self tagKeyForNode:parent]];
}

// TODO -(void)removeNode:(PGSourceViewNode* )parent {
//
//}

-(PGSourceViewNode* )nodeAtIndex:(NSInteger)index parent:(PGSourceViewNode* )parent {
	// if parent==nil, than use tag 0 or else determine tag for this node
	// get tag for this node
	// TODO
}

-(NSInteger)numberOfChildrenOfParent:(PGSourceViewNode* )parent {
	// if parent==nil, than use tag 0 or else determine tag for this node
	// get tag for this node
	// TODO
}

-(NSDictionary* )dictionary {
	NSMutableArray* nodes = [NSMutableArray arrayWithCapacity:[_tags count]];
	for(id key in _tags) {
		PGSourceViewNode* node = [self nodeForTagKey:key];
		NSParameterAssert(node);
		[nodes addObject:[node dictionaryWithKey:key]];
	}
	
	return @{
		@"nodes": nodes,
		@"children": _children
	};
}

@end
