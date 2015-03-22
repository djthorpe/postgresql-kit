
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

#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

const NSDictionary* PGSchemaProductOpLookup = nil;

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchemaProductOp

////////////////////////////////////////////////////////////////////////////////
// private methods

+(void)initialize {
	PGSchemaProductOpLookup = @{
		@"create-table":    @"PGSchemaProductOpTable",
		@"update-table":    @"PGSchemaProductOpTable",
		@"drop-table":      @"PGSchemaProductOpTable",
		@"create-view":     @"PGSchemaProductOpView",
		@"update-view":     @"PGSchemaProductOpView",
		@"drop-view":       @"PGSchemaProductOpView",
		@"create-index":    @"PGSchemaProductOpIndex",
		@"update-index":    @"PGSchemaProductOpIndex",
		@"drop-index":      @"PGSchemaProductOpIndex",
		@"create-type":     @"PGSchemaProductOpType",
		@"update-type":     @"PGSchemaProductOpType",
		@"drop-type":       @"PGSchemaProductOpType",
		@"create-function": @"PGSchemaProductOpFunction",
		@"update-function": @"PGSchemaProductOpFunction",
		@"drop-function":   @"PGSchemaProductOpFunction"
	};
}

////////////////////////////////////////////////////////////////////////////////
// constructor

+(PGSchemaProductOp* )operationWithXMLNode:(NSXMLElement* )node {
	NSParameterAssert(PGSchemaProductOpLookup);
	NSParameterAssert(node);
	Class opclass = NSClassFromString([PGSchemaProductOpLookup objectForKey:[node name]]);
	if(!opclass) {
		return nil;
	}
	return [[opclass alloc] initWithXMLNode:node];
}

-(id)init {
	return nil;
}

-(id)initWithXMLNode:(NSXMLElement* )node {
	NSParameterAssert(node);
	self = [super init];
	if(self) {
		_attributes = [NSMutableDictionary dictionaryWithCapacity:[[node attributes] count]];
		for(NSXMLNode* attr in [node attributes]) {
			NSString* key = [attr name];
			if([_attributes objectForKey:key]==nil) {
				// only first attribute of the same name is allowed
				[_attributes setValue:[attr stringValue] forKey:key];
			} else {
				NSLog(@"Warning: ignored repeated attribute: %@",key);
			}
		}
		[_attributes setValue:[[node stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"cdata"];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize attributes = _attributes;

////////////////////////////////////////////////////////////////////////////////
// methods

-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorInternal description:@"createWithConnection not implemented"];
	return NO;
}

-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorInternal description:@"updateWithConnection not implemented"];
	return NO;
}

-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorInternal description:@"dropWithConnection not implemented"];
	return NO;
}

@end
