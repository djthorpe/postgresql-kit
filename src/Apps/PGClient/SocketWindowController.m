
#import "SocketWindowController.h"
#import <PGClientKit/PGClientKit.h>

@interface SocketWindowController ()

@end

@implementation SocketWindowController

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
    }
    return self;
}

-(void)windowDidLoad {
    [super windowDidLoad];
	NSLog(@"windowDidLoad");
}

-(NSString* )windowNibName {
	return @"SocketConnectionWindow";
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize port = _port;
@synthesize path = _path;
@synthesize username = _username;
@synthesize database = _database;
@dynamic displayedPath;
@dynamic defaultPort;

-(NSString* )displayedPath {
	if([_path length]==0) {
		return @"";
	}
	NSString* displayedPath = [NSString stringWithFormat:@".../%@",[[self path] lastPathComponent]];
	return displayedPath;
}

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

-(void)_chooseNewSocketPath:(NSString* )newPath {
	NSLog(@"new path = %@",newPath);
	[self willChangeValueForKey:@"displayedPath"];
	[self setPath:newPath];
	[self didChangeValueForKey:@"displayedPath"];
	NSLog(@"new path = %@",[self displayedPath]);
}

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
