
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

@implementation PGSchemaProductNV

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithName:(NSString* )name version:(NSUInteger)version {
	NSParameterAssert(name);
	NSParameterAssert(version > 0);
	self = [super init];
	if(self) {
		_name = name;
		_version = version;
	}
	return self;	
}

-(id)initWithXMLNode:(NSXMLElement* )node {
	NSParameterAssert(node);
	self = [super init];
	if(self) {
		NSString* nameString =
			[[[node attributeForName:@"name"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSString* versionString =
			[[[node attributeForName:@"version"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if(nameString==nil || versionString==nil) {
			return nil;
		}
		int versionInt = [versionString intValue];
		if(versionInt <= 0 || [[NSString stringWithFormat:@"%d",versionInt] isEqual:versionString]==NO) {
			return nil;
		}
		_name = nameString;
		_version = (NSUInteger)versionInt;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize name= _name;
@synthesize version = _version;
@dynamic key;

-(NSString* )key {
	return [NSString stringWithFormat:@"%@,%lu",[self name],[self version]];
}

////////////////////////////////////////////////////////////////////////////////
// description

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ name=\"%@\" version=\"%lu\">",NSStringFromClass([self class]),[self name],[self version]];
}

@end
