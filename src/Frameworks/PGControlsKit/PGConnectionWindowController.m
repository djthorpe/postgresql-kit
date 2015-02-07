
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

#import <PGClientKit/PGClientKit.h>
#import <PGControlsKit/PGControlsKit.h>

////////////////////////////////////////////////////////////////////////////////

NSTimeInterval PingTimerInterval = 2.0; // two seconds until a ping is made

////////////////////////////////////////////////////////////////////////////////

@interface PGConnectionWindowController ()

// IB Properties
@property (weak,nonatomic) IBOutlet NSWindow* ibPasswordWindow;
@property (weak,nonatomic) IBOutlet NSWindow* ibURLWindow;
@property (weak,nonatomic) IBOutlet NSWindow* ibErrorWindow;

// Other Properties
@property (readonly) PGConnection* connection;
@property (readonly) NSMutableDictionary* params;
@property BOOL isDefaultPort;
@property BOOL isUseKeychain;
@property BOOL isRequireSSL;
@property BOOL isValidConnection;
@property NSString* errorTitle;
@property NSString* errorDescription;
@property (readonly) NSString* username;
@property (readonly) NSURL* url;
@property (retain) NSTimer* pingTimer;
@property (retain) NSImage* pingImage;

// ibactions
-(IBAction)ibButtonClicked:(id)sender;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGConnectionWindowController

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_connection = [PGConnection new];
		_params = [NSMutableDictionary new];
		NSParameterAssert(_connection && _params);
	}
	return self;
}

-(NSString* )windowNibName {
	return @"PGConnectionWindow";
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize params = _params;

@synthesize ibPasswordWindow;
@synthesize ibURLWindow;
@synthesize isDefaultPort;
@synthesize isUseKeychain;
@synthesize isRequireSSL;
@synthesize pingTimer;
@synthesize pingImage;
@synthesize isValidConnection;
@synthesize errorTitle;
@synthesize errorDescription;
@dynamic url;

-(NSURL* )url {
	return [NSURL URLWithPostgresqlParams:[self params]];
}

/*
-(void)setUrl:(NSURL* )url {
	NSParameterAssert(url);
	NSDictionary* params = [url postgresqlParameters];
	[_params removeAllObjects];
	if(params) {
		[_params setDictionary:params];
	}
}

-(NSInteger)tag {
	return [[self connection] tag];
}

-(void)setTag:(NSInteger)value {
	[[self connection] setTag:value];
}
*/

////////////////////////////////////////////////////////////////////////////////
// static methods

+(NSURL* )defaultNetworkURL {
	return [NSURL URLWithHost:@"localhost" port:PGClientDefaultPort ssl:YES username:NSUserName() database:NSUserName() params:nil];
}

+(NSURL* )defaultSocketURL {
	return [NSURL URLWithSocketPath:NSHomeDirectory() port:PGClientDefaultPort database:NSUserName() username:NSUserName() params:nil];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

+(NSImage* )resourceImageNamed:(NSString* )name {
	NSBundle* bundle = [NSBundle bundleForClass:self];
	return [bundle imageForResource:name];
}

-(void)windowDidLoad {
    [super windowDidLoad];
	// set some defaults
	[self setIsDefaultPort:YES];
	[self setIsRequireSSL:YES];
	[self setIsValidConnection:NO];
	[self setIsUseKeychain:YES];
}

-(void)_setDefaultValuesFrom:(NSDictionary* )params {
	// replace existing dictionary
	[[self params] removeAllObjects];
	[[self params] setValuesForKeysWithDictionary:params];

	// set user
	NSString* user = [params objectForKey:@"user"];
	if([user length]==0) {
		user = NSUserName();
		[[self params] setObject:user forKey:@"user"];
	}
	NSParameterAssert([user isKindOfClass:[NSString class]]);

	// set dbname
	NSString* dbname = [params objectForKey:@"dbname"];
	if([dbname length]==0) {
		dbname = user;
		[[self params] setObject:dbname forKey:@"dbname"];
	}
	NSParameterAssert([dbname isKindOfClass:[NSString class]]);

	// set host
	NSString* host = [params objectForKey:@"host"];
	if([host length]==0) {
		host = @"localhost";
		[[self params] setObject:host forKey:@"host"];
	}
	
	// set port
	NSNumber* port = [params objectForKey:@"port"];
	if([port isKindOfClass:[NSNumber class]]) {
		if([port unsignedIntegerValue]==PGClientDefaultPort) {
			[self setIsDefaultPort:YES];
		}
	} else {
		port = [NSNumber numberWithUnsignedInteger:PGClientDefaultPort];
		[self setIsDefaultPort:YES];
		[[self params] setObject:port forKey:@"port"];
	}
	
	// set SSL
	NSString* sslmode = [params objectForKey:@"sslmode"];
	if([sslmode isEqualToString:@"require"]) {
		[self setIsRequireSSL:YES];
		[[self params] setObject:@"require" forKey:@"sslmode"];
	} else {
		[[self params] setObject:@"prefer" forKey:@"sslmode"];
		[self setIsRequireSSL:NO];
	}
	
	// set ping image
	[self setPingImage:[[self class] resourceImageNamed:@"traffic-grey"]];
}

/*

-(void)_setErrorValues {
	if([self lastError]==nil) {
		[self setErrorTitle:@"Unknown Error"];
		[self setErrorDescription:@"An unknown error occurred."];
		return;
	}
	
	[self setErrorTitle:@"Connection Error"];
	[self setErrorDescription:[[self lastError] localizedDescription]];
	
}
*/

////////////////////////////////////////////////////////////////////////////////
// private methods - ping timer

-(void)_schedulePingTimer {
	[[self pingTimer] invalidate];
	[self setPingTimer:[NSTimer scheduledTimerWithTimeInterval:PingTimerInterval target:self selector:@selector(_doPingTimer:) userInfo:nil repeats:NO]];
	[self setPingImage:[[self class] resourceImageNamed:@"traffic-orange"]];
}

-(void)_unschedulePingTimer {
	[[self pingTimer] invalidate];
	[self setPingTimer:nil];
	[self setPingImage:[[self class] resourceImageNamed:@"traffic-red"]];
}

-(void)_doPingTimer:(id)sender {
	[self _unschedulePingTimer];
	NSURL* url = [self url];
	if(url) {
		[self setPingImage:[[self class] resourceImageNamed:@"traffic-orange"]];
		[self setIsValidConnection:NO];
		
		// TODO: Do ping in background, with a timeout
		NSError* error = nil;
		if([_connection pingWithURL:url error:&error]==NO) {
			[self setPingImage:[[self class] resourceImageNamed:@"traffic-red"]];
			[self setIsValidConnection:NO];
		} else {
			[self setPingImage:[[self class] resourceImageNamed:@"traffic-green"]];
			[self setIsValidConnection:YES];
		}
		if(error) {
			NSLog(@"_doPingTimer: error: %@",error);
		}
	} else {
		[self setPingImage:[[self class] resourceImageNamed:@"traffic-red"]];
		[self setIsValidConnection:NO];
	}
}

////////////////////////////////////////////////////////////////////////////////
// private methods - key-value observing

-(void)_registerAsObserver:(NSWindow* )window {
	if(window==[self window]) {
		for(NSString* keyPath in @[ @"isDefaultPort",@"isRequireSSL",@"params.host", @"params.ssl", @"params.user", @"params.dbname", @"params.port" ]) {
			[self addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
		}
	}
}

-(void)_deregisterAsObserver:(NSWindow* )window {
	if(window==[self window]) {
		for(NSString* keyPath in @[ @"isDefaultPort",@"isRequireSSL",@"params.host", @"params.ssl", @"params.user", @"params.dbname", @"params.port" ]) {
			[self removeObserver:self forKeyPath:keyPath];
		}
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	
	// check for isDefaultPort
	if([keyPath isEqualToString:@"isDefaultPort"]) {
		[self willChangeValueForKey:@"params.port"];
		[[self params] setObject:[NSNumber numberWithUnsignedInteger:PGClientDefaultPort] forKey:@"port"];
		[self didChangeValueForKey:@"params.port"];
	}

	// check for isRequireSSL
	if([keyPath isEqualToString:@"isRequireSSL"]) {
		[self willChangeValueForKey:@"params.sslmode"];
		BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if(newValue==YES) {
			[[self params] setObject:@"require" forKey:@"sslmode"];
		} else {
			[[self params] setObject:@"prefer" forKey:@"sslmode"];
		}
		[self didChangeValueForKey:@"params.sslmode"];
	}
	
	// schedule timer to check for value values
	if([self url]) {
		[self _schedulePingTimer];
	} else {
		[self _unschedulePingTimer];
	}
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)beginConnectionSheetWithURL:(NSURL* )url parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url)) callback {
	NSParameterAssert(parentWindow);
	
	// register as observer
	[self _registerAsObserver:[self window]];

	// set default URL
	if(url==nil) {
		url = [PGConnectionWindowController defaultNetworkURL];
	}

	// set parameters
	[self _setDefaultValuesFrom:[url postgresqlParameters]];
	
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnValue) {
		// cancel timers
		[self _unschedulePingTimer];
		// remove observers
		[self _deregisterAsObserver:[self window]];
		// for cancel, return nil
		if(returnValue==NSModalResponseCancel) {
			callback(nil);
		} else {
			callback([self url]);
		}
	}];
}

-(void)beginPasswordSheetWithParentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSString* password,BOOL useKeychain)) callback {
	NSParameterAssert(parentWindow);

	// register as observer
	[self _registerAsObserver:[self ibPasswordWindow]];
	
	// set parameters
	// TODO
	
	[parentWindow beginSheet:[self ibPasswordWindow] completionHandler:^(NSModalResponse returnValue) {
		// remove observers
		[self _deregisterAsObserver:[self ibPasswordWindow]];
		// for cancel, return nil
		if(returnValue==NSModalResponseCancel) {
			callback(nil,NO);
		} else {
			NSString* password = [[self params] objectForKey:@"password"];
			callback(password,[self isUseKeychain]);
		}
	}];
}

-(void)beginErrorSheetForParentWindow:(NSWindow* )parentWindow {
	[self _registerAsObserver:[self ibErrorWindow]];

	// set parameters
	//[self _setErrorValues];

	// start sheet
	[NSApp beginSheet:[self ibErrorWindow] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

/*

-(void)endSheet:(NSWindow* )theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	// remove sheet
	[theSheet orderOut:self];

	// remove observer
	[self _deregisterAsObserver:theSheet];
	
	// stop ping timer
	if(theSheet==[self window]) {
		[self _unschedulePingTimer];
	}
	*/
	/*
	// determine return status
	PGConnectionWindowStatus status = PGConnectionWindowStatusOK;
	
	if(returnCode==NSModalResponseCancel) {
		// if cancel button is pressed
		status = PGConnectionWindowStatusCancel;
	} else if (returnCode==NSModalResponseOK) {
		// OK button pressed
		if([self url]==nil) {
			status = PGConnectionWindowStatusBadParameters;
		} else {
			status = PGConnectionWindowStatusOK;
		}
	} else {
		// Retry....
		status = PGConnectionWindowStatusRetry;
	}

	// send message to delegate
	if([[self delegate] respondsToSelector:@selector(connectionWindow:status:)]) {
		[[self delegate] connectionWindow:self status:status];
	}
}
	*/

/*
-(void)connect {
	if([self url]==nil) {
		[[self delegate] connectionWindow:self status:PGConnectionWindowStatusBadParameters];
		return;
	}
	
	[[self delegate] connectionWindow:self status:PGConnectionWindowStatusConnecting];
	[[self connection] connectInBackgroundWithURL:[self url] whenDone:^(NSError* error){
		if([error code]==PGClientErrorNeedsPassword) {
			[[self delegate] connectionWindow:self status:PGConnectionWindowStatusNeedsPassword];
		} else if(error==nil) {
			NSString* password = [[self params] objectForKey:@"password"];
			NSError* error = nil;
			// Store Password if the password was used during connection
			if([[self connection] connectionUsedPassword] && [password length]) {
				[[self password] setPassword:password forURL:[self url] saveToKeychain:[self isUseKeychain] error:&error];
			}
			[self connection:[self connection] error:error];
			[[self delegate] connectionWindow:self status:PGConnectionWindowStatusConnected];
		} else {
			[[self delegate] connectionWindow:self status:PGConnectionWindowStatusRejected];
		}
	}];
}

-(void)disconnect {
	if([[self connection] status]==PGConnectionStatusConnected) {
		[[self connection] disconnect];
	}
}
*/

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibButtonClicked:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	NSWindow* theWindow = [(NSButton* )sender window];
	NSWindow* parentWindow = [theWindow sheetParent];
	
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel
		[parentWindow endSheet:theWindow returnCode:NSModalResponseCancel];
	} else if([[(NSButton* )sender title] hasPrefix:@"Try"]) {
		// Try again...
		[parentWindow endSheet:theWindow returnCode:NSModalResponseContinue];
	} else if([[(NSButton* )sender title] isEqualToString:@"OK"]) {
		// OK
		[parentWindow endSheet:theWindow returnCode:NSModalResponseOK];
	} else {
		// Unknown button clicked
		NSLog(@"Button clicked, ignoring: %@",sender);
	}
}

@end
