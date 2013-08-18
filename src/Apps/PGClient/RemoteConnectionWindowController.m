
#import "RemoteConnectionWindowController.h"
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
@dynamic defaultPort;

-(void)setDefaultPort:(BOOL)value {
	if(value) {
		[self setPort:5832];
	}
	_defaultPort = value;
}

-(BOOL)defaultPort {
	return _defaultPort;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow {
	// set parameters
	[self setDefaultPort:YES];
	
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	[theSheet orderOut:self];
	if(returnCode != NSOKButton) {
		NSLog(@"Cancel pressed");
	} else {
		NSLog(@"OK pressed");
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
