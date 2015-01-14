
#import <PGClientKit/PGClientKit.h>
#import "PGControlsKit.h"

////////////////////////////////////////////////////////////////////////////////

NSTimeInterval PingTimerInterval = 2.0; // two seconds until a ping is made

////////////////////////////////////////////////////////////////////////////////

@interface PGConnectionWindowController ()

// IB Properties
@property (weak,nonatomic) IBOutlet NSWindow* ibPasswordWindow;
@property (weak,nonatomic) IBOutlet NSWindow* ibURLWindow;

// Other Properties
@property BOOL isDefaultPort;
@property BOOL isUseKeychain;
@property BOOL isRequireSSL;
@property (readonly) NSMutableDictionary* params;
@property (readonly) NSString* username;
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
		_password = [PGPasswordStore new];
		_connection = [PGConnection new];
		_params = [NSMutableDictionary new];
		NSParameterAssert(_password && _connection && _params);
		[_connection setDelegate:self];
	}
	return self;
}

-(NSString* )windowNibName {
	return @"PGConnectionWindow";
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize password = _password;
@synthesize params = _params;

@synthesize ibPasswordWindow;
@synthesize ibURLWindow;

@synthesize isDefaultPort;
@synthesize isUseKeychain;
@synthesize isRequireSSL;
@synthesize pingTimer;
@synthesize pingImage;
@dynamic url;

-(NSURL* )url {
	return [NSURL URLWithPostgresqlParams:[self params]];
}

-(void)setUrl:(NSURL* )url {
	NSParameterAssert(url);
	NSDictionary* params = [url postgresqlParameters];
	[_params removeAllObjects];
	if(params) {
		[_params setDictionary:params];
	}
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
}

-(void)_setDefaultValues {
	// set user
	NSString* user = [[self params] objectForKey:@"user"];
	if([user length]==0) {
		user = NSUserName();
		[[self params] setObject:user forKey:@"user"];
	}
	NSParameterAssert([user isKindOfClass:[NSString class]]);

	// set dbname
	NSString* dbname = [[self params] objectForKey:@"dbname"];
	if([dbname length]==0) {
		dbname = user;
		[[self params] setObject:dbname forKey:@"dbname"];
	}
	NSParameterAssert([dbname isKindOfClass:[NSString class]]);

	// set host
	NSString* host = [[self params] objectForKey:@"host"];
	if([host length]==0) {
		host = @"localhost";
		[[self params] setObject:host forKey:@"host"];
	}
	
	// set port
	NSNumber* port = [[self params] objectForKey:@"port"];
	if([port isKindOfClass:[NSNumber class]]) {
		if([port unsignedIntegerValue]==PGClientDefaultPort) {
			[self setIsDefaultPort:YES];
		}
	} else {
		[self setIsDefaultPort:YES];
		[[self params] setObject:[NSNumber numberWithUnsignedInteger:PGClientDefaultPort] forKey:@"port"];
	}
	
	// set SSL
	NSString* sslmode = [[self params] objectForKey:@"sslmode"];
	if([sslmode isEqualToString:@"require"]) {
		[self setIsRequireSSL:YES];
	} else {
		[[self params] setObject:@"prefer" forKey:@"sslmode"];
		[self setIsRequireSSL:NO];
	}
	
	// set ping image
	[self setPingImage:[[self class] resourceImageNamed:@"traffic-grey"]];
}

////////////////////////////////////////////////////////////////////////////////
// private methods - ping timer

-(void)_schedulePingTimer {
	if([self pingTimer]==nil) {
		[self setPingTimer:[NSTimer scheduledTimerWithTimeInterval:PingTimerInterval target:self selector:@selector(_doPingTimer:) userInfo:nil repeats:NO]];
		[self setPingImage:[[self class] resourceImageNamed:@"traffic-orange"]];
	}
}

-(void)_unschedulePingTimer {
	if([self pingTimer]) {
		[[self pingTimer] invalidate];
	}
	[self setPingTimer:nil];
	[self setPingImage:[[self class] resourceImageNamed:@"traffic-red"]];
}

-(void)_doPingTimer:(id)sender {
	[self _unschedulePingTimer];
	NSURL* url = [self url];
	if(url) {
		[self setPingImage:[[self class] resourceImageNamed:@"traffic-orange"]];
		
		// TODO: Do ping in background, with a timeout
		NSError* error = nil;
		if([_connection pingWithURL:url error:&error]==NO) {
			[self setPingImage:[[self class] resourceImageNamed:@"traffic-red"]];
		} else {
			[self setPingImage:[[self class] resourceImageNamed:@"traffic-green"]];
		}
		if(error && [[self delegate] respondsToSelector:@selector(connectionWindow:error:)]) {
			[[self delegate] connectionWindow:self error:error];
		}
	} else {
		[self setPingImage:[[self class] resourceImageNamed:@"traffic-red"]];
	}
}

////////////////////////////////////////////////////////////////////////////////
// private methods - key-value observing

-(void)_registerAsObserver {
	for(NSString* keyPath in @[ @"isDefaultPort",@"isRequireSSL",@"params.host", @"params.ssl", @"params.user", @"params.dbname", @"params.port" ]) {
		[self addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}

-(void)_deregisterAsObserver {
	for(NSString* keyPath in @[ @"isDefaultPort",@"isRequireSSL",@"params.host", @"params.ssl", @"params.user", @"params.dbname", @"params.port" ]) {
		[self removeObserver:self forKeyPath:keyPath];
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	NSLog(@"%@ => %@",keyPath,change);
	
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

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow {
	// register as observer
	[self _registerAsObserver];

	// set parameters
	[self _setDefaultValues];
	
	// start sheet
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)beginPasswordSheetForParentWindow:(NSWindow* )parentWindow {
	// TODO: set password

	// start sheet
	[NSApp beginSheet:[self ibPasswordWindow] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)endSheet:(NSWindow* )theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	// remove sheet
	[theSheet orderOut:self];

	// remove observer
	[self _deregisterAsObserver];
	
	// stop ping timer
	[self _unschedulePingTimer];
	
	// determine return status
	PGConnectionWindowStatus status = PGConnectionWindowStatusOK;
	
	// if cancel button is pressed
	if(returnCode==NSModalResponseCancel) {
		status = PGConnectionWindowStatusCancel;
	} else if (returnCode==NSModalResponseOK && [self url]==nil) {
		status = PGConnectionWindowStatusBadParameters;
	}

	// send message to delegate
	[[self delegate] connectionWindow:self status:status];
}

-(void)connect {
	if([self url]==nil) {
		[[self delegate] connectionWindow:self status:PGConnectionWindowStatusBadParameters];
		return;
	}
	[[self connection] connectInBackgroundWithURL:[self url] whenDone:^(NSError* error){
		if([error code]==PGClientErrorNeedsPassword) {
			[[self delegate] connectionWindow:self status:PGConnectionWindowStatusNeedsPassword];
		}
	}];
}

-(void)disconnect {
	if([[self connection] status]==PGConnectionStatusConnected) {
		[[self connection] disconnect];
	}
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibButtonClicked:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	NSWindow* theWindow = [(NSButton* )sender window];

	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed, immediately quit
		[NSApp endSheet:theWindow returnCode:NSModalResponseCancel];
	} else {
		// Do something here
		[NSApp endSheet:theWindow returnCode:NSModalResponseOK];
	}
}

////////////////////////////////////////////////////////////////////////////////
// PGConnectionDelegate delegate implementation

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {
	// store and retrieve password
	NSParameterAssert([self password]);
	NSError* error = nil;
	if([dictionary objectForKey:@"password"]) {
		NSError* error = nil;
		[[self password] setPassword:[dictionary objectForKey:@"password"] forURL:[self url] saveToKeychain:YES error:&error];
	} else {
		NSString* password = [[self password] passwordForURL:[self url] error:&error];
		if(password) {
			[dictionary setObject:password forKey:@"password"];
		}
	}
	if(error) {
		[self connection:connection error:error];
	}
}

-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status {
	switch(status) {
		case PGConnectionStatusConnecting:
			[[self delegate] connectionWindow:self status:PGConnectionWindowStatusConnecting];
			break;
		case PGConnectionStatusConnected: {
				// Store Password
				NSString* password = [[self params] objectForKey:@"password"];
				NSError* error = nil;
				if([password length]) {
					[[self password] setPassword:password forURL:[self url] saveToKeychain:[self isUseKeychain] error:&error];
				}
				if(error) {
					[self connection:[self connection] error:error];
				}
				[[self delegate] connectionWindow:self status:PGConnectionWindowStatusConnected];
			}
			break;
		case PGConnectionStatusRejected:
			[[self delegate] connectionWindow:self status:PGConnectionWindowStatusRejected];
			break;
		default:
			NSLog(@"PGConnection sent status %d",status);
	}
}

-(void)connection:(PGConnection* )connection error:(NSError* )theError {
	if([[self delegate] respondsToSelector:@selector(connectionWindow:error:)]) {
		[[self delegate] connectionWindow:self error:theError];
	} else {
		NSLog(@"Connection Error: %@",[theError localizedDescription]);
	}
}

@end
