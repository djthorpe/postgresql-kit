
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

 /**
  *  The parameter bindings for this dialog are as follows:
  *
  *  user - NSString* username
  *  dbname - NSString* database
  *  host - NSString* hostname
  *  port - NSUInteger port
  *  is_default_port - BOOL
  *  is_require_ssl - BOOL
  *  comment - NSString*
  *
  *  Programmatically, the following parameters are also generated:
  *
  *  sslmode - NSString*
  *  hostaddr - NSString*
  *  is_valid_connection - BOOL
  */

@implementation PGDialogNetworkConnectionView

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@dynamic port;
@dynamic sslmode;

-(NSInteger)port {
	NSNumber* nsport = [[self parameters] objectForKey:@"port"];
	if([nsport isKindOfClass:[NSNumber class]]==NO) {
		return 0;
	}
	NSInteger port = [nsport integerValue];
	if(port < 1 || port > PGClientMaximumPort) {
		return 0;
	}
	return port;
}

-(NSString* )sslmode {
	NSString* sslmode = [[self parameters] objectForKey:@"sslmode"];
	if([sslmode isEqualTo:@"prefer"]) {
		return @"prefer";
	} else {
		return @"require";
	}
}

-(NSArray* )bindings {
	return @[ @"user",@"dbname",@"host",@"port",@"is_default_port",@"is_require_ssl",@"comment" ];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(void)updateViewParameters {

	// port
	if([self port]==PGClientDefaultPort) {
		[[self parameters] setObject:[NSNumber numberWithBool:YES] forKey:@"is_default_port"];
	} else {
		[[self parameters] setObject:[NSNumber numberWithBool:NO] forKey:@"is_default_port"];
	}

	// sslmode
	if([[self sslmode] isEqualTo:@"prefer"]) {
		[[self parameters] setObject:[NSNumber numberWithBool:NO] forKey:@"is_require_ssl"];
	} else {
		[[self parameters] setObject:[NSNumber numberWithBool:YES] forKey:@"is_require_ssl"];
	}
}

-(void)setViewParameters:(NSDictionary* )parameters {
	[super setViewParameters:parameters];

	// update parameters
	[self updateViewParameters];
}

-(void)viewDidEnd {
	[super viewDidEnd];
}

@end
