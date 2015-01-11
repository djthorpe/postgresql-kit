
#import <PGClientKit/PGClientKit.h>
#import "PGControlsKit.h"

////////////////////////////////////////////////////////////////////////////////

@interface PGConnectionWindowController ()

// properties
@property (readonly) NSMutableDictionary* params;
@property (readonly) NSString* username;
@property (readonly) BOOL isUseKeychain;

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
@dynamic url;
@dynamic isUseKeychain;

-(NSURL* )url {
	return [NSURL URLWithPostgresqlParams:[self params]];
}

-(BOOL)isUseKeychain {
	return YES;
}

-(void)setUrl:(NSURL* )url {
	NSParameterAssert(url);
	NSDictionary* params = [url postgresqlParameters];
	if(params) {
		[_params removeAllObjects];
		[_params setDictionary:params];
	} else {
		NSLog(@"Error: setUrl: Unable to set parameters from URL: %@",url);
	}
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)setDefaultValues {
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
	
}

-(void)beginSheetForParentWindow:(NSWindow* )parentWindow contextInfo:(void* )contextInfo {
	// set parameters
	[self setDefaultValues];

	// start sheet
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:contextInfo];
}

-(void)endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	// remove sheet
	[theSheet orderOut:self];
	// send message to delegate
	if([[self delegate] respondsToSelector:@selector(connectionWindow:endedWithStatus:contextInfo:)]) {
		[[self delegate] connectionWindow:self endedWithStatus:returnCode contextInfo:contextInfo];
	}
}

-(BOOL)connect {
	if([self url]==nil) {
		return NO;
	}
	return [[self connection] connectInBackgroundWithURL:[self url] whenDone:^(NSError* error){
		if([error code]==PGClientErrorNeedsPassword) {
			NSLog(@"NEEDS PASSWORD TO BE ENTERED");
		}
	}];
}

-(void)disconnect {
	if([[self connection] status]==PGConnectionStatusConnected) {
		[[self connection] disconnect];
	}
}

-(void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibButtonClicked:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		// Cancel button pressed, immediately quit
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSModalResponseCancel];
	} else {
		// Do something here
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSModalResponseOK];
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

/*
-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status {

	// disconnected
	if([self stopping] && status==PGConnectionStatusDisconnected) {
		// indicate server connection has been shutdown
		[self stoppedWithReturnValue:0];
		return;
	}
	
	// connected
	//if(status==PGConnectionStatusConnected && [self shouldStorePassword] && [self temporaryPassword]) {
	//	PGPasswordStore* store = [PGPasswordStore new];
	//	NSLog(@"TODO: Store password: %@",[self temporaryPassword]);
	//}
	
}
*/

-(void)connection:(PGConnection* )connection error:(NSError* )theError {
	if([[self delegate] respondsToSelector:@selector(connectionWindow:error:)]) {
		[[self delegate] connectionWindow:self error:theError];
	} else {
		NSLog(@"Connection Error: %@",theError);
	}
}

@end
