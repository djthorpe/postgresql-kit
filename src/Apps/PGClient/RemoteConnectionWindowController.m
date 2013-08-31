
#import "RemoteConnectionWindowController.h"
#import "PGClientApplication.h"
#import <PGClientKit/PGClientKit.h>

NSTimeInterval PingTimerInterval = 2.0;

@implementation RemoteConnectionWindowController

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)initWithWindow:(NSWindow* )window {
    self = [super initWithWindow:window];
    if (self) {
		_connection = [[PGConnection alloc] init];
    }
    return self;
}

-(void)windowDidLoad {
    [super windowDidLoad];
}

-(NSString* )windowNibName {
	return @"RemoteConnectionWindow";
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize hostname;
@synthesize database;
@synthesize username;
@synthesize applicationName;
@synthesize requireEncryption;
@synthesize validParameters;
@synthesize ibAdvancedOptionsBox;
@synthesize port;
@synthesize defaultPort;
@synthesize timeout;
@synthesize showAdvancedOptions;
@synthesize pingTimer;

@dynamic timeoutString;
@dynamic url;

-(NSString* )timeoutString {
	if([self timeout]==0) {
		return @"Default";
	} else {
		return [NSString stringWithFormat:@"%lu sec%c",[self timeout],[self timeout]==1 ? ' ' : 's'];
	}
}

-(NSURL* )url {
	// check hostname
	if([[self hostname] length]==0) {
		return nil;
	}
	// check port
	if([self port] < 1 || [self port] > PGClientMaximumPort) {
		return nil;
	}
	// check username
	if([[self username] length]==0) {
		return nil;
	}
	// check username valid characters
	NSCharacterSet* usernameChars = [NSCharacterSet characterSetWithCharactersInString:@"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
	NSRange usernameTest = [[self username] rangeOfCharacterFromSet:[usernameChars invertedSet]];
	if(usernameTest.location != NSNotFound) {
		return nil;
	}
	// set parameters
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:2];
	if([self timeout]) {
		[params setObject:[NSNumber numberWithUnsignedInteger:[self timeout]] forKey:@"connect_timeout"];
	}
	if([self applicationName]) {
		[params setObject:[NSNumber numberWithUnsignedInteger:[self applicationName]] forKey:@"application_name"];
	}
	// return URL
	return [NSURL URLWithHost:[self hostname] port:[self port] ssl:[self requireEncryption] username:[self username] database:[self database] params:params];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_toggleWindowSize {
	NSRect frameSize = [[self window] frame];
	if(frameSize.size.height==[[self window] maxSize].height) {
        frameSize.size = [[self window] minSize];
        frameSize.origin.y += [[self window] maxSize].height - [[self window] minSize].height;
	} else {
        frameSize.size = [[self window] maxSize];
        frameSize.origin.y -= [[self window] maxSize].height - [[self window] minSize].height;
	}
	if([self showAdvancedOptions]) {
		[[[self ibAdvancedOptionsBox] animator] setAlphaValue:1.0];
	} else {
		[[[self ibAdvancedOptionsBox] animator] setAlphaValue:0.0];
	}
	[[self window] setFrame:frameSize display:YES animate:YES];
}

-(void)_setValidParameters {
	[self willChangeValueForKey:@"validParameters"];
	[self setValidParameters:[self url] ? YES : NO];
	[self didChangeValueForKey:@"validParameters"];
}

-(void)_schedulePingTimer {
	if([self pingTimer]==nil) {
		[self setPingTimer:[NSTimer scheduledTimerWithTimeInterval:PingTimerInterval target:self selector:@selector(_doPingTimer:) userInfo:nil repeats:NO]];
		[self setStatusImage:[NSImage imageNamed:@"traffic-grey"]];
	}
}

-(void)_unschedulePingTimer {
	if([self pingTimer]) {
		[[self pingTimer] invalidate];
	}
	[self setPingTimer:nil];
	[self setStatusImage:[NSImage imageNamed:@"traffic-grey"]];
}

-(void)_doPingTimer:(NSTimer* )timer {
	[self _unschedulePingTimer];
	NSURL* url = [self url];
	if(url) {
		NSError* error = nil;
		// TODO: Do ping in background
		if([_connection pingWithURL:url error:&error]==NO) {
			[self setStatusImage:[NSImage imageNamed:@"traffic-red"]];
#ifdef DEBUG
			NSLog(@"PING %@ => %@",url,error);
#endif
		} else {
			[self setStatusImage:[NSImage imageNamed:@"traffic-green"]];
		}
	} else {
		[self setStatusImage:[NSImage imageNamed:@"traffic-grey"]];
	}
}

////////////////////////////////////////////////////////////////////////////////
// private methods - key-value observing

-(void)_registerAsObserver {
	for(NSString* keyPath in @[ @"username",@"database",@"hostname",@"timeout",@"port",@"applicationName",@"defaultPort",@"requireEncryption",@"showAdvancedOptions" ]) {
		[self addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}

-(void)_deregisterAsObserver {
	for(NSString* keyPath in @[ @"username",@"database",@"hostname",@"timeout",@"port",@"applicationName",@"defaultPort",@"requireEncryption",@"showAdvancedOptions" ]) {
		[self removeObserver:self forKeyPath:keyPath];
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	if([keyPath isEqual:@"port"]) {
		NSUInteger newPort = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
		if(newPort==PGServerDefaultPort) {
			[self setDefaultPort:YES];
		} else {
			[self setDefaultPort:NO];
		}
	} else if([keyPath isEqual:@"defaultPort"]) {
		BOOL isDefaultPort = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if(isDefaultPort) {
			[self setPort:PGServerDefaultPort];
		}
	} else if([keyPath isEqual:@"timeout"]) {
		[self willChangeValueForKey:@"timeoutString"];
		[self didChangeValueForKey:@"timeoutString"];
	} else if([keyPath isEqual:@"showAdvancedOptions"]) {
		[self _toggleWindowSize];
		// nothing changed, so return directly without validation
		return;
	}

	[self _setValidParameters];
	
	// if we have valid parameters
	if([self validParameters]) {
		[self _schedulePingTimer];
	} else {
		[self _unschedulePingTimer];
	}
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow {
	// set parameters
	[self setValue:[NSNumber numberWithUnsignedInteger:PGServerDefaultPort] forKeyPath:@"port"];
	[self setValue:[NSNumber numberWithBool:NO] forKeyPath:@"showAdvancedOptions"];
	[self setValue:[NSNumber numberWithBool:YES] forKeyPath:@"requireEncryption"];
	[self setValue:NSUserName() forKeyPath:@"username"];
	// set state
	[self _toggleWindowSize];
	[self _setValidParameters];
	// set KVO
	[self _registerAsObserver];
	// set ping timer
	[self _schedulePingTimer];
	// start sheet
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	// remove sheet
	[theSheet orderOut:self];
	// unset KVO
	[self _deregisterAsObserver];
	// remove ping timer
	[self _unschedulePingTimer];
	// perform action
	if(returnCode==NSOKButton) {
		// send notification for adding an item into the sidebar
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientAddConnectionURL object:[self url]];
		NSLog(@"Added URL: %@",[self url]);
	}
}

////////////////////////////////////////////////////////////////////////////////
// ibactions

-(IBAction)ibEndSheetForButton:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed, immediately quit
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSCancelButton];
	} else {
		// Do something here
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
	}
}

@end
