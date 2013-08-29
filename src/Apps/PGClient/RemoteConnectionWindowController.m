
#import "RemoteConnectionWindowController.h"
#import "PGClientApplication.h"
#import <PGClientKit/PGClientKit.h>

@implementation RemoteConnectionWindowController

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)initWithWindow:(NSWindow* )window {
    self = [super initWithWindow:window];
    if (self) {
		_hostname = @"";
		_username = @"";
		_database = @"";
		_port = 0;
		_defaultPort = YES;
		_requireEncryption = NO;
		_timeout = 0;
		_showAdvancedOptions = NO;
		_validParameters = NO;
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

@synthesize port = _port;
@synthesize hostname = _bostname;
@synthesize username = _username;
@synthesize database = _database;
@synthesize requireEncryption = _requireEncryption;
@synthesize validParameters = _validParameters;
@synthesize ibAdvancedOptionsBox;
@dynamic showAdvancedOptions;
@dynamic defaultPort;
@dynamic timeoutString;
@dynamic timeout;

-(void)setDefaultPort:(BOOL)value {
	if(value) {
		[self setPort:5832];
	}
	_defaultPort = value;
}

-(BOOL)defaultPort {
	return _defaultPort;
}

-(void)setTimeout:(NSUInteger)value {
	[self willChangeValueForKey:@"timeoutString"];
	[self willChangeValueForKey:@"timeout"];
	_timeout = value;
	[self didChangeValueForKey:@"timeoutString"];
	[self didChangeValueForKey:@"timeout"];
}

-(NSUInteger)timeout {
	return _timeout;
}

-(void)setShowAdvancedOptions:(BOOL)value {
	_showAdvancedOptions = value;
	[self _toggleWindowSize];
}

-(BOOL)showAdvancedOptions {
	return _showAdvancedOptions;
}

-(NSString* )timeoutString {
	if([self timeout]==0) {
		return @"Default";
	} else {
		return [NSString stringWithFormat:@"%lu sec%c",[self timeout],[self timeout]==1 ? ' ' : 's'];
	}
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

-(BOOL)_checkConnectionParameters {
	// check hostname
	if([[self hostname] length]==0) {
		return NO;
	}
	// check port
	if([self port] < 1 || [self port] > PGClientMaximumPort) {
		return NO;
	}
	// check username
	if([[self username] length]==0) {
		return NO;
	}
	// check username valid characters
	NSCharacterSet* usernameChars = [NSCharacterSet characterSetWithCharactersInString:@"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
	NSRange usernameTest = [[self username] rangeOfCharacterFromSet:[usernameChars invertedSet]];
	if(usernameTest.location != NSNotFound) {
		return NO;
	}
	// success
	return YES;
}

-(void)_setValidParameters {
	[self willChangeValueForKey:@"validParameters"];
	_validParameters = [self _checkConnectionParameters];
	[self didChangeValueForKey:@"validParameters"];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow {
	// set parameters
	[self setDefaultPort:YES];
	[self setShowAdvancedOptions:NO];
	[self _setValidParameters];
	
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {
		// add connection
		NSURL* url = [NSURL URLWithHost:[self hostname] port:[self port] ssl:[self requireEncryption] username:[self username] database:[self database] params:nil];
		// send notification for adding an item into the sidebar
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientAddConnectionURL object:url];
		NSLog(@"Added URL: %@",url);
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
