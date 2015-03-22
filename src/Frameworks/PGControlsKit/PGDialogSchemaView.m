
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

@implementation PGDialogSchemaView

 /**
  *  The parameter bindings for this dialog are as follows:
  *
  *  schema - NSString* username
  *  owner - NSString* database
  *  roles - NSArray* of roles
  *  comment - NSString* hostname
  */

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic transaction;
@dynamic schema;
@dynamic owner;
@dynamic comment;

-(PGTransaction* )transaction {
	PGQuerySchema* query = nil;
	PGQuerySchema* comment = nil;
	PGTransaction* transaction = [PGTransaction new];
	if([[self schema] length]) {
		query = [PGQuerySchema create:[self schema] options:0];
		comment = [PGQuerySchema comment:[self comment] schema:[self schema]];
		[query setOwner:[self owner]];
		[transaction add:query];
		[transaction add:comment];
	}
	return (query && comment) ? transaction : nil;
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
#pragma mark Public Methods
////////////////////////////////////////////////////////////////////////////////

-(void)setRoles:(NSArray* )roles {
	NSString* owner = [self owner];

	// set the roles which can be chosen
	[[self parameters] setObject:roles forKey:@"roles"];

	// reset the owner name
	if(owner && [roles containsObject:owner]) {
		[[self parameters] setObject:owner forKey:@"owner"];
	} else if([roles count]) {
		[[self parameters] setObject:[roles objectAtIndex:0] forKey:@"owner"];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGDialogView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)valueChangedWithKey:(NSString* )key oldValue:(id)oldValue newValue:(id)newValue {
	[super valueChangedWithKey:key oldValue:oldValue newValue:newValue];

	// validate OK button
	if([[self schema] length]) {
		[self setEnabled:YES];
	} else {
		[self setEnabled:NO];
	}
}

-(void)setViewParameters:(NSDictionary* )parameters {
	[super setViewParameters:parameters];
	
	// add owner to the list of roles
	if([self owner]) {
		[[self parameters] setObject:@[ [self owner] ] forKey:@"roles"];
	} else {
		[[self parameters] setObject:@[ ] forKey:@"roles"];
	}
	
	// empty comment
	[[self parameters] removeObjectForKey:@"comment"];
}

@end
