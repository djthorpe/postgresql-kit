
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

@interface PGDialogDatabaseView ()
@property NSUInteger connectionLimitMinValue;
@property NSUInteger connectionLimitMaxValue;
@end

const NSTimeInterval PGDialogDatabaseConnectionLimitMaxValue = 20;
NSString* PGDialogDatabaseTemplateDefault = @"(default)";
NSString* PGDialogDatabaseTablespaceDefault = @"pg_default";

@implementation PGDialogDatabaseView

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic query;
@dynamic database;
@dynamic owner;
@dynamic template;
@dynamic tablespace;
@dynamic comment;
@dynamic connectionLimit;
@synthesize connectionLimitMinValue;
@synthesize connectionLimitMaxValue;

-(PGQuery* )query {
	PGQueryDatabase* query = nil;
	if([[self database] length]) {
		query = [PGQueryDatabase create:[self database] options:0];
		if([self connectionLimit]==(PGDialogDatabaseConnectionLimitMaxValue + 1)) {
			[query setConnectionLimit:-1];
		} else {
			[query setConnectionLimit:[self connectionLimit]];
		}
		[query setOwner:[self owner]];
		[query setTemplate:[self template]];
		[query setTablespace:[self tablespace]];
	}
	return query;
}


-(NSString* )database {
	return [[[self parameters] objectForKey:@"database"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )owner {
	return [[self parameters] objectForKey:@"owner"];
}

-(NSString* )template {
	NSString* template = [[self parameters] objectForKey:@"template"];
	if([template isEqualToString:PGDialogDatabaseTemplateDefault]) {
		return nil;
	} else {
		return template;
	}
}

-(NSString* )tablespace {
	NSString* tablespace = [[self parameters] objectForKey:@"tablespace"];
	if([tablespace isEqualToString:PGDialogDatabaseTablespaceDefault]) {
		return nil;
	} else {
		return tablespace;
	}
}

-(NSString* )comment {
	return [[[self parameters] objectForKey:@"comment"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSInteger)connectionLimit {
	NSNumber* connectionLimit = [[self parameters] objectForKey:@"connection_limit"];
	NSInteger connectionLimit2 = (PGDialogDatabaseConnectionLimitMaxValue + 1);
	if(connectionLimit && [connectionLimit isKindOfClass:[NSNumber class]]) {
		connectionLimit2 = [connectionLimit integerValue];
	}
	if(connectionLimit2 >= 0 && connectionLimit2 <= (PGDialogDatabaseConnectionLimitMaxValue + 1)) {
		return connectionLimit2;
	}
	return (PGDialogDatabaseConnectionLimitMaxValue + 1);
}

-(NSArray* )bindings {
	return @[ @"database",@"owner",@"comment",@"template",@"tablespace",@"connection_limit" ];
}

-(NSString* )windowTitle {
	return @"Create Database";
}

-(NSString* )windowDescription {
	return @"Create a new database";
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

-(void)updateConnectionLimitLabel {
	// update the label to reflect the current value
	NSInteger connectionLimit = [self connectionLimit];
	if(connectionLimit==0) {
		[[self parameters] setObject:@"No Login" forKey:@"connection_limit_text"];
	} else if(connectionLimit==(PGDialogDatabaseConnectionLimitMaxValue + 1)) {
		[[self parameters] setObject:@"Unlimited" forKey:@"connection_limit_text"];
	} else {
		[[self parameters] setObject:[NSNumber numberWithInteger:connectionLimit] forKey:@"connection_limit_text"];
	}
	[[self parameters] setObject:[NSNumber numberWithInteger:connectionLimit] forKey:@"connection_limit"];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Public Methods
////////////////////////////////////////////////////////////////////////////////

-(void)setRoles:(NSArray* )roles {
	NSParameterAssert(roles);

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

-(void)setTemplates:(NSArray* )templates {
	NSParameterAssert(templates);

	// store the current value
	NSString* template = [self template];

	// set the templates which can be chosen, but include a "default" value
	NSMutableArray* values = [NSMutableArray arrayWithArray:templates];
	[values insertObject:PGDialogDatabaseTemplateDefault atIndex:0];
	[[self parameters] setObject:values forKey:@"templates"];

	// reset the template name
	if(template && [values containsObject:template]) {
		[[self parameters] setObject:template forKey:@"template"];
	} else if([values count]) {
		[[self parameters] setObject:[values objectAtIndex:0] forKey:@"template"];
	}
}

-(void)setTablespaces:(NSArray* )tablespaces {
	NSParameterAssert(tablespaces);

	// store the current value
	NSString* tablespace = [self tablespace];

	// set the tablespaces which can be chosen, but include a "default" value
	NSMutableArray* values = [NSMutableArray arrayWithArray:tablespaces];
	if([values containsObject:PGDialogDatabaseTablespaceDefault]==NO) {
		[values insertObject:PGDialogDatabaseTablespaceDefault atIndex:0];
	}
	[[self parameters] setObject:values forKey:@"tablespaces"];

	// reset the tablespace name
	if(tablespace && [values containsObject:tablespace]) {
		[[self parameters] setObject:tablespace forKey:@"tablespace"];
	} else if([values count]) {
		[[self parameters] setObject:[values objectAtIndex:0] forKey:@"tablespace"];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGDialogView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)valueChangedWithKey:(NSString* )key oldValue:(id)oldValue newValue:(id)newValue {
	[super valueChangedWithKey:key oldValue:oldValue newValue:newValue];

	// connection limit
	if([key isEqualToString:@"connection_limit"]) {
		[self updateConnectionLimitLabel];
	}

	// validate OK button
	if([[self database] length]) {
		[self setEnabled:YES];
	} else {
		[self setEnabled:NO];
	}
}

-(void)setViewParameters:(NSDictionary* )parameters {
	[super setViewParameters:parameters];
	
	// set connection limit
	[self setConnectionLimitMinValue:0];
	[self setConnectionLimitMaxValue:(PGDialogDatabaseConnectionLimitMaxValue + 1)];
	[self updateConnectionLimitLabel];
	
	// add owner to the list of roles
	if([self owner]) {
		[[self parameters] setObject:@[ [self owner] ] forKey:@"roles"];
	} else {
		[[self parameters] setObject:@[ ] forKey:@"roles"];
	}
	
	// set templates and tablespaces to default
	[self setTemplates:@[ ]];
	[self setTablespaces:@[ ]];
}


@end
