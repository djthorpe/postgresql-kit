
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
		_parameters = [[NSMutableDictionary alloc] init];
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

@synthesize parameters = _parameters;
@synthesize validParameters;
@synthesize ibAdvancedOptionsBox;
@synthesize pingTimer;
@dynamic timeoutString;
@dynamic url;

-(NSUInteger)timeout {
	NSNumber* timeout = self.parameters[@"connect_timeout"];
	if([timeout isKindOfClass:[NSNumber class]]==NO) {
		return 0;
	} else {
		return [timeout unsignedIntegerValue];
	}
}

-(NSString* )timeoutString {
	if([self timeout]==0) {
		return @"Default";
	} else {
		return [NSString stringWithFormat:@"%lu sec%c",[self timeout],[self timeout]==1 ? ' ' : 's'];
	}
}

-(NSURL* )url {
	return [NSURL URLWithPostgresqlParams:[self parameters]];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_toggleWindowSize:(BOOL)toggle {
	NSRect frameSize = [[self window] frame];
	if(toggle==NO) {
        frameSize.size = [[self window] minSize];
        frameSize.origin.y += [[self window] maxSize].height - [[self window] minSize].height;
		[[[self ibAdvancedOptionsBox] animator] setAlphaValue:0.0];
	} else {
        frameSize.size = [[self window] maxSize];
        frameSize.origin.y -= [[self window] maxSize].height - [[self window] minSize].height;
		[[[self ibAdvancedOptionsBox] animator] setAlphaValue:1.0];
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
	for(NSString* keyPath in @[ @"parameters.host", @"parameters.ssl", @"parameters.user", @"parameters.dbname", @"parameters.port", @"parameters.defaultPort", @"parameters.connect_timeout", @"parameters.application_name", @"parameters.advanced" ]) {
		[self addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}

-(void)_deregisterAsObserver {
	for(NSString* keyPath in @[ @"parameters.host", @"parameters.ssl", @"parameters.user", @"parameters.dbname", @"parameters.port", @"parameters.defaultPort", @"parameters.connect_timeout", @"parameters.application_name", @"parameters.advanced" ]) {
		[self removeObserver:self forKeyPath:keyPath];
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	// toggle advanced option
	if([keyPath isEqual:@"parameters.advanced"]) {
		NSNumber* advancedToggle = [change objectForKey:NSKeyValueChangeNewKey];
		[self _toggleWindowSize:[advancedToggle boolValue]];
	} else if([keyPath isEqual:@"parameters.port"]) {
		// do nothing
	} else if([keyPath isEqual:@"parameters.defaultPort"]) {
		BOOL isDefaultPort = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if(isDefaultPort) {
			[[self parameters] setValue:[NSNumber numberWithUnsignedInteger:PGClientDefaultPort] forKey:@"port"];
		}
	} else if([keyPath isEqual:@"parameters.connect_timeout"]) {
		[self willChangeValueForKey:@"timeoutString"];
		[self didChangeValueForKey:@"timeoutString"];
	} else if([keyPath isEqual:@"parameters.ssl"]) {
		BOOL isSSL = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		[[self parameters] setObject:(isSSL ? @"require" : @"prefer") forKey:@"sslmode"];
	}

	if([self url]) {
		[self _schedulePingTimer];
	} else {
		[self _unschedulePingTimer];
	}
	NSLog(@"%@ => %@",[self parameters],[self url]);
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow url:(NSURL* )url {

	// set KVO
	[self _registerAsObserver];

	// set parameters
	if(url==nil) {
		[[self parameters] removeAllObjects];
		[[self parameters] setValue:[NSNumber numberWithBool:YES] forKey:@"defaultPort"];
		[[self parameters] setValue:[NSNumber numberWithBool:YES] forKey:@"ssl"];
	} else {
		[[self parameters] setDictionary:[url postgresqlParameters]];
	}
	// set state
	[self _toggleWindowSize:NO];
	[self _setValidParameters];
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
