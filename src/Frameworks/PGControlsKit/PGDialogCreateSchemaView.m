
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

#import <PGControlsKit/PGControlsKit.h>
#import <PGControlsKit/PGControlsKit+Private.h>

@implementation PGDialogCreateSchemaView

 /**
  *  The parameter bindings for this dialog are as follows:
  *
  *  schema - NSString* username
  *  owner - NSString* database
  *  comment - NSString* hostname
  */

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic query;
@dynamic schema;
@dynamic owner;
@dynamic comment;

-(PGQuery* )query {
	if([[self schema] length]==0) {
		return nil;
	}
	PGQuerySchema* query = [PGQuerySchema create:[self schema] options:0];
	if([[self owner] length]) {
		[query setOwner:[self owner]];
	}
	return query;
}

-(NSString* )schema {
	return [[[self parameters] objectForKey:@"schema"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )owner {
	return [[[self parameters] objectForKey:@"owner"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )comment {
	return [[[self parameters] objectForKey:@"comment"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSArray* )bindings {
	return @[ @"schema",@"owner",@"comment" ];
}

-(NSString* )windowTitle {
	return @"Create Schema";
}

-(NSString* )windowDescription {
	return @"Create a new schema in the database";
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods
////////////////////////////////////////////////////////////////////////////////

/**
 *  Method to message the delegate to enable or disable the OK button
 */
-(void)setEnabled:(BOOL)enabled {
	int flag = enabled ? PGDialogWindowFlagEnabled : PGDialogWindowFlagDisabled;
	if([[self delegate] respondsToSelector:@selector(view:setFlags:description:)]) {
		[[self delegate] view:self setFlags:flag description:nil];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGDialogView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)valueChangedWithKey:(NSString* )key oldValue:(id)oldValue newValue:(id)newValue {
	[super valueChangedWithKey:key oldValue:oldValue newValue:newValue];

	NSLog(@"value %@ %@=>%@ query=>%@",key,oldValue,newValue,[self query]);

	// validate OK button
	if([[self schema] length]) {
		[self setEnabled:YES];
	} else {
		[self setEnabled:NO];
	}
}

@end
