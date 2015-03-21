
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

@interface PGDialogNetworkConnectionView ()
@property NSTimer* timer;
@property (readonly) PGConnection* connection;
@property (readonly) NSLock* waitLock;
@end

const NSTimeInterval PGDialogNetworkConnectionPingDelayInterval = 2.0;

 /**
  *  The parameter bindings for this dialog are as follows:
  *
  *  user - NSString* username
  *  dbname - NSString* database
  *  host - NSString* hostname
  *  port - NSUInteger port
  *  comment - NSString*
  *
  *  Programmatically, the following parameters are also generated:
  *
  *  sslmode - NSString*
  *  hostaddr - NSString*
  */

@implementation PGDialogNetworkConnectionView

////////////////////////////////////////////////////////////////////////////////
#pragma mark constructor
////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
    self = [super init];
    if (self) {
		_timer = nil;
		_connection = [PGConnection new];
		_waitLock = [NSLock new];
		NSParameterAssert(_connection);
		NSParameterAssert(_waitLock);
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark properties
////////////////////////////////////////////////////////////////////////////////

@synthesize timer = _timer;
@synthesize connection = _connection;
@synthesize waitLock = _waitLock;
@dynamic host,hostaddr,user,dbname,sslmode,port,url,comment;

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

-(NSString* )user {
	return [[[self parameters] objectForKey:@"user"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )dbname {
	return [[[self parameters] objectForKey:@"dbname"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )hostaddr {
	return [[[self parameters] objectForKey:@"hostaddr"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )host {
	return [[[self parameters] objectForKey:@"host"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString* )comment {
	return [[[self parameters] objectForKey:@"comment"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSArray* )bindings {
	return @[ @"user",@"dbname",@"host",@"port",@"is_default_port",@"is_require_ssl",@"comment" ];
}

-(NSURL* )url {
	NSMutableDictionary* url = [NSMutableDictionary dictionaryWithDictionary:[self parameters]];

	// remove parameters which aren't part of the URL
	[url removeObjectForKey:@"comment"];
	[url removeObjectForKey:@"is_require_ssl"];
	[url removeObjectForKey:@"is_default_port"];
	
	// if missing user or dbname, return nil
	if([self user]==nil) {
		return nil;
	}
	if([self dbname]==nil) {
		return nil;
	}
	
	// convert host into hostaddr
	if([[self host] isNetworkAddress]) {
		[url removeObjectForKey:@"host"];
		[url setObject:[self host] forKey:@"hostaddr"];
	} else if([[self host] isNetworkHostname]) {
		[url removeObjectForKey:@"hostaddr"];	
	} else {
		return nil;
	}
	
	return [NSURL URLWithPostgresqlParams:url];
}

-(NSString* )windowTitle {
	return @"Create Network Connection";
}

-(NSString* )windowDescription {
	return @"Enter the details for the connection to the remote PostgreSQL database";
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

/**
 *  Method to reset parameters based on others within the parameter dictionary
 */
-(void)resetViewParameters {
	// port
	BOOL isDefaultPort = ([self port]==PGClientDefaultPort) ? YES : NO;
	[[self parameters] setObject:[NSNumber numberWithBool:isDefaultPort] forKey:@"is_default_port"];

	// sslmode
	BOOL isRequireSSL = ([[self sslmode] isEqualTo:@"prefer"]) ? NO : YES;
	[[self parameters] setObject:[NSNumber numberWithBool:isRequireSSL] forKey:@"is_require_ssl"];

	// hostaddr
	if([self hostaddr]) {
		[[self parameters] setObject:[self hostaddr] forKey:@"host"];
	}
}

/**
 *  Method to remove the timer
 */
-(void)invalidateTimer {
	[[self timer] invalidate];
	[self setTimer:nil];
}

/**
 *  Method to reset the timer, so that it delays the ping, or calls immediately
 */
-(void)resetTimerWithDelay:(BOOL)isDelayed {
	if([self timer]) {
		[self invalidateTimer];
		NSParameterAssert([self timer]==nil);
	}
	
	NSTimeInterval timeInterval = isDelayed ? PGDialogNetworkConnectionPingDelayInterval : 0.0;
	NSTimer* scheduledTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(triggeredTimer:) userInfo:nil repeats:NO];
	NSParameterAssert(scheduledTimer);
	[self setTimer:scheduledTimer];
}

/**
 *  Method to message the delegate the current indicator status
 */
-(void)setIndicatorFlag:(int)flag description:(NSString* )description {
	if([[self delegate] respondsToSelector:@selector(view:setFlags:description:)]) {
		[[self delegate] view:self setFlags:flag description:description];
	}
}

/**
 *  Initiate the ping if it isn't already in progress
 */
-(void)triggeredTimer:(id)sender {
	// do the ping
	NSURL* url = [self url];
	[self setIndicatorFlag:PGDialogWindowFlagIndicatorOrange description:[NSString stringWithFormat:@"ping=%@",url]];
	if(url==nil) {
		[self setIndicatorFlag:PGDialogWindowFlagIndicatorRed description:nil];
		return;
	}
	// perform the lock
	if([[self waitLock] tryLock]==NO) {
		[self resetTimerWithDelay:YES];
		return;
	}
	// perform the ping
	[[self connection] pingWithURL:url whenDone:^(NSError* error) {
		[[self waitLock] unlock];
		if(error) {
			[self setIndicatorFlag:PGDialogWindowFlagIndicatorRed description:[error localizedDescription]];
		} else {
			[self setIndicatorFlag:(PGDialogWindowFlagEnabled | PGDialogWindowFlagIndicatorGreen) description:nil];
		}
	}];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark PGDialogView overrides
////////////////////////////////////////////////////////////////////////////////

-(void)valueChangedWithKey:(NSString* )key oldValue:(id)oldValue newValue:(id)newValue {
	[super valueChangedWithKey:key oldValue:oldValue newValue:newValue];
	
	// if default port checkbox clicked, then set the value in the 'port' field
	if([key isEqualTo:@"is_default_port"] && [newValue isKindOfClass:[NSNumber class]]) {
		BOOL newBool = [(NSNumber* )newValue boolValue];
		if(newBool==YES) {
			[[self parameters] setObject:[NSNumber numberWithInteger:PGClientDefaultPort] forKey:@"port"];
		}
	}

	// if the "require ssl" checkbox is clicked, then set the sslmode to "require", or
	// else set it to "prefer"
	if([key isEqualTo:@"is_require_ssl"] && [newValue isKindOfClass:[NSNumber class]]) {
		BOOL newBool = [(NSNumber* )newValue boolValue];
		if(newBool==YES) {
			[[self parameters] setObject:@"require" forKey:@"sslmode"];
		} else {
			[[self parameters] setObject:@"prefer" forKey:@"sslmode"];
		}
	}
	
	// if it's not the comment which was changed, then reset the ping
	if([key isNotEqualTo:@"comment"]) {
		// set the indicator
		[self setIndicatorFlag:PGDialogWindowFlagIndicatorOrange description:nil];
		// reset the timer
		[self resetTimerWithDelay:YES];
	}
}

-(void)setViewParameters:(NSDictionary* )parameters {
	[super setViewParameters:parameters];

	// update parameters
	[self resetViewParameters];
	
	// schedule timer
	[self resetTimerWithDelay:NO];
}

-(void)viewDidEnd {
	[self invalidateTimer];	
	[super viewDidEnd];
}

@end
