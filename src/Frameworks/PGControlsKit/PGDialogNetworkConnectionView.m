
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
  *  is_default_port - BOOL
  *  is_require_ssl - BOOL
  *  comment - NSString*
  *
  *  Programmatically, the following parameters are also generated:
  *
  *  sslmode - NSString*
  */

//postgres://pttnkktdoyjfyc@ec2-54-227-255-156.compute-1.amazonaws.com:5432/dej7aj0jp668p5

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

@dynamic port;
@dynamic sslmode;
@synthesize timer = _timer;
@synthesize connection = _connection;
@synthesize waitLock = _waitLock;
@dynamic url;

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

-(NSURL* )url {
	NSMutableDictionary* url = [NSMutableDictionary dictionaryWithDictionary:[self parameters]];
	[url removeObjectForKey:@"comment"];
	[url removeObjectForKey:@"is_require_ssl"];
	[url removeObjectForKey:@"is_default_port"];
	[url removeObjectForKey:@"window_title"];
	[url removeObjectForKey:@"window_description"];
	return [NSURL URLWithPostgresqlParams:url];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods
////////////////////////////////////////////////////////////////////////////////

-(void)resetViewParameters {
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

-(void)invalidateTimer {
	[[self timer] invalidate];
	[self setTimer:nil];
}

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

-(void)triggeredTimer:(id)sender {
	// do the ping
	NSURL* url = [self url];
	if(url==nil) {
		NSLog(@"STATE = BAD PARAMETERS");
		return;
	}
	// perform the lock
	NSLog(@"STATE = BUSY");	
	if([[self waitLock] tryLock]==NO) {
		[self resetTimerWithDelay:YES];
		return;
	}
	// perform the ping
	[[self connection] pingWithURL:url whenDone:^(NSError* error) {
		[[self waitLock] unlock];
		if(error) {
			NSLog(@"STATE = BAD PARAMETERS: %@",[error localizedDescription]);
		} else {
			NSLog(@"STATE = OK");
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
	
	// reset the timer
	[self resetTimerWithDelay:YES];
	
	if([key isNotEqualTo:@"comment"]) {
		// set the comment
		[[self parameters] setObject:[self url] forKey:@"comment"];
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
