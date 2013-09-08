
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
// parameters are user, port, dbname, host/hostaddr, sslmode (require/prefer)
// application_name connect_timeout application_name client_encoding

@synthesize validParameters;
@synthesize ibAdvancedOptionsBox;
@synthesize defaultPort;
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
	return [NSURL URLWithPostgresqlParams:[self parameters]];
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
	for(NSString* keyPath in @[ @"parameters" ]) {
		[self addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}

-(void)_deregisterAsObserver {
	for(NSString* keyPath in @[ @"parameters" ]) {
		[self removeObserver:self forKeyPath:keyPath];
	}
}

-(void)observeValueForKeyPath:(NSString* )keyPath ofObject:(id)object change:(NSDictionary* )change context:(void* )context {
	NSLog(@"Changed %@",keyPath);
/*	if([keyPath isEqual:@"portString"]) {
		NSString* newPort = [change objectForKey:NSKeyValueChangeNewKey];
		NSUInteger port = [self _portForString:newPort];
		if(port==PGClientDefaultPort) {
			[self setDefaultPort:YES];
		} else {
			[self setDefaultPort:NO];
		}
	} else if([keyPath isEqual:@"defaultPort"]) {
		BOOL isDefaultPort = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if(isDefaultPort && [self port] != PGClientDefaultPort) {
			[self setPortString:[NSString stringWithFormat:@"%lu",PGClientDefaultPort]];
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
	}*/
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow url:(NSURL* )url {
	// set parameters
	if(url==nil) {
		/*
		// reset to defaults
		[self setPortString:[NSString stringWithFormat:@"%lu",PGClientDefaultPort]];
		[self setDefaultPort:YES];
		[self setUsername:NSUserName()];
		[self setDatabase:@""];
		[self setHostname:@""];
		[self setTimeout:0];
		[self setRequireEncryption:YES];
		[self setApplicationName:@""];
		 */
	} else {
		/*
		// extract parameters
		NSDictionary* parameters = [PGConnection extractParametersFromURL:url];
		[self setPortString:[parameters objectForKey:@"port"]];
		[self setUsername:[parameters objectForKey:@"user"]];
		 */
	}
/*
	[self setValue:[NSNumber numberWithBool:NO] forKeyPath:@"showAdvancedOptions"];
	[self setValue:[NSNumber numberWithBool:YES] forKeyPath:@"requireEncryption"];
*/
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
