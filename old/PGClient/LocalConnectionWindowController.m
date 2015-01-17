
#import "LocalConnectionWindowController.h"
#import "PGClientApplication.h"
#import <PGClientKit/PGClientKit.h>

@interface LocalConnectionWindowController (Private)
-(void)_setValidParameters;
@end

@implementation LocalConnectionWindowController

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)initWithWindow:(NSWindow* )window {
    self = [super initWithWindow:window];
    if (self) {
		_path = @"";
		_username = @"";
		_database = @"";
		_port = 0;
		_defaultPort = YES;
		_validParameters = NO;
    }
    return self;
}

-(void)windowDidLoad {
    [super windowDidLoad];
}

-(NSString* )windowNibName {
	return @"LocalConnectionWindow";
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize path = _path;
@synthesize database = _database;
@synthesize validParameters = _validParameters;
@dynamic username;
@dynamic port;
@dynamic displayedPath;
@dynamic defaultPort;

-(NSString* )displayedPath {
	if([_path length]==0) {
		return @"";
	}
	NSString* displayedPath = [NSString stringWithFormat:@".../%@",[[self path] lastPathComponent]];
	return displayedPath;
}

-(NSString* )username {
	return _username;
}

-(void)setUsername:(NSString* )value {
	[self willChangeValueForKey:@"username"];
	_username = value;
	[self didChangeValueForKey:@"username"];
	[self _setValidParameters];
}

-(NSUInteger)port {
	return _port;
}

-(void)setPort:(NSUInteger)port {
	[self willChangeValueForKey:@"port"];
	[self willChangeValueForKey:@"defaultPort"];
	if(port==0 || port==PGClientDefaultPort) {
		_port = PGClientDefaultPort;
		_defaultPort = YES;
	} else {
		_port = port;
		_defaultPort = NO;
	}
	[self didChangeValueForKey:@"port"];
	[self didChangeValueForKey:@"defaultPort"];
	[self _setValidParameters];
}

-(void)setDefaultPort:(BOOL)value {
	[self willChangeValueForKey:@"defaultPort"];
	[self willChangeValueForKey:@"port"];
	if(value) {
		_port = PGClientDefaultPort;
		_defaultPort = YES;
	} else {
		_defaultPort = NO;
	}
	[self didChangeValueForKey:@"port"];
	[self didChangeValueForKey:@"defaultPort"];
	[self _setValidParameters];
}

-(BOOL)defaultPort {
	return _defaultPort;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_chooseNewSocketPath:(NSString* )newPath {
	[self willChangeValueForKey:@"displayedPath"];
	[self setPath:newPath];
	[self didChangeValueForKey:@"displayedPath"];
	[self _setValidParameters];
}

-(BOOL)_checkConnectionParameters {
	// check input path
	if([[self path] length]==0) {
		return NO;
	}
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self path] isDirectory:&isDirectory]==NO) {
		return NO;
	}
	if([[NSFileManager defaultManager] isReadableFileAtPath:[self path]]==NO) {
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
	NSCharacterSet* usernameChars = [NSCharacterSet characterSetWithCharactersInString:@"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
	NSRange usernameTest = [[self username] rangeOfCharacterFromSet:[usernameChars invertedSet]];
	if(usernameTest.location != NSNotFound) {
		return NO;
	}
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
	[self setPort:PGClientDefaultPort];
	[self setDefaultPort:YES];
	[self _chooseNewSocketPath:@""];
	[self setUsername:NSUserName()];
	[self setDatabase:@""];
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(_endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)_endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {
		// add connection
		NSURL* url = [NSURL URLWithSocketPath:[self path] port:[self port] database:[self database] username:[self username] params:nil];
		// send notification for adding an item into the sidebar
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientAddConnectionURL object:url];
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

-(IBAction)ibDoChooseFolder:(id)sender {
	// show folder choosing option
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode) {
		if(returnCode==NSOKButton) {
			if([[panel URLs] count]==1) {
				NSURL* url = [[panel URLs] objectAtIndex:0];
				[self _chooseNewSocketPath:[url path]];
			}
		}
	}];
}

@end
