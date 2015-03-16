
#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow* window;
@property (retain) PGConnection* connection;
@property (retain) PGDialogWindow* dialog;
@property (retain) NSURL* url;
@property (readonly) NSString* urlstring;
@end

@implementation AppDelegate

@dynamic urlstring;

-(NSString* )urlstring {
	return [[self url] absoluteString];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// create connection class and dialog window
	[self setConnection:[PGConnection new]];
	[self setDialog:[PGDialogWindow new]];
	[[self dialog] load];

	// set delegates
	[[self connection] setDelegate:self];
	[[self dialog] setDelegate:self];
	
	
	// get user default for url
	NSString* url = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
	if(url) {
		[super willChangeValueForKey:@"urlstring"];
		[self setUrl:[NSURL URLWithString:url]];
		[super didChangeValueForKey:@"urlstring"];
	}
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	[[self connection] disconnect];
}

-(void)handleLoginError:(NSError* )error {
/*
	if([[error domain] isEqualToString:PGClientErrorDomain] && [error code]==PGClientErrorNeedsPassword) {
		[[self dialog] beginPasswordSheetWithParentWindow:[self window] whenDone:^(NSString* password, BOOL useKeychain) {
			NSLog(@"SAVE PASSWORD: %@",error);
		}];
		return;
	}

	[[self dialog] beginErrorSheetWithError:error parentWindow:[self window] whenDone:^(NSModalResponse response) {
		if(response==NSModalResponseContinue) {
			[self doCreateConnectionURL:nil];
		}
	}];
*/
}

-(IBAction)doCreateConnectionURL:(id)sender {
	[[self dialog] beginNetworkConnectionSheetWithURL:[self url] parentWindow:[self window] whenDone:^(NSURL *url, NSModalResponse response) {
		if(response==NSModalResponseOK && url) {
			// set the URL
			[super willChangeValueForKey:@"urlstring"];
			[self setUrl:url];
			[super didChangeValueForKey:@"urlstring"];

			// save URL
			[[NSUserDefaults standardUserDefaults] setObject:[[self url] absoluteString] forKey:@"url"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}];
}

-(IBAction)doCreateRoleWindow:(id)sender {
	[[self dialog] loadWindow];
	PGDialogView* view = [[self dialog] ibCreateRoleView];
	[[self dialog] beginCustomSheetWithTitle:@"Create new role" description:nil view:view parentWindow:[self window] whenDone:^(NSModalResponse response) {
		NSLog(@"DONE, RESPONSE = %ld",response);
	}];
}

-(IBAction)doCreateSchemaWindow:(id)sender {
	[[self dialog] loadWindow];
	PGDialogView* view = [[self dialog] ibCreateSchemaView];
	[[self dialog] beginCustomSheetWithTitle:@"Create new schema" description:nil view:view parentWindow:[self window] whenDone:^(NSModalResponse response) {
		NSLog(@"DONE, RESPONSE = %ld",response);
	}];
}

-(IBAction)doCreateDatabaseWindow:(id)sender {
	[[self dialog] loadWindow];
	PGDialogView* view = [[self dialog] ibCreateDatabaseView];
	[[self dialog] beginCustomSheetWithTitle:@"Create new database" description:nil view:view parentWindow:[self window] whenDone:^(NSModalResponse response) {
		NSLog(@"DONE, RESPONSE = %ld",response);
	}];
}

-(IBAction)doLogin:(id)sender {
	if([self url]) {
		[[self connection] connectWithURL:[self url] whenDone:^(BOOL usedPassword, NSError *error) {
			if(error) {
				[self handleLoginError:error];
			}
		}];
	}
}

-(IBAction)doLogout:(id)sender {
	[[self connection] disconnect];
}

-(void)window:(PGDialogWindow* )controller dialogWillOpenWithParameters:(NSMutableDictionary *)parameters {
	NSLog(@"dialog:willopenwithparameters:%@",parameters);
}


@end
