
#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow* window;
@property (nonatomic, retain) PGConnection* connection;
@property (nonatomic, retain) PGPasswordStore* passwordstore;
@property (retain) PGDialogWindow* dialog;
@property (retain) NSURL* url;
@property (readonly) NSString* urlstring;
@property BOOL connected;
@property BOOL disconnected;
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
	[self setPasswordstore:[PGPasswordStore new]];
	[self setConnected:NO];
	[self setDisconnected:YES];
	[[self dialog] load];

	// set delegates
	[[self connection] setDelegate:self];
	
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

-(void)execute:(PGQuery* )query {
	NSLog(@"execute: %@",[query quoteForConnection:[self connection] error:nil]);
	[[self connection] execute:query whenDone:^(PGResult *result, NSError *error) {
		if([result size]) {
			NSLog(@"%@",[result tableWithWidth:60]);
		}
		if(error) {
			NSLog(@"ERROR: %@",error);
		}
	}];
}

-(void)handleLoginError:(NSError* )error {
	if([error isNeedsPassword]) {
		[self doPassword:nil];
		return;
	} else if([error isBadPassword]) {
		// remove password from password store
		[[self passwordstore] removePasswordForURL:[self url] saveToKeychain:YES error:nil];
	}
	// TODO: Show error message
	NSLog(@"ERROR %@",error);
}

-(IBAction)doPassword:(id)sender {
	[[self dialog] beginPasswordSheetSaveInKeychain:YES parentWindow:[self window] whenDone:^(NSString* password, BOOL saveInKeychain) {
		if(password) {
			// in the first instance, don't store it in the keychain
			[[self passwordstore] setPassword:password forURL:[self url] saveToKeychain:NO];
			// perform login
			[self doLogin:sender];
		}
	}];
}

-(IBAction)doCreateNetworkURL:(id)sender {
	NSURL* defaultURL = [PGDialogWindow defaultNetworkURL];
	[[self dialog] beginConnectionSheetWithURL:defaultURL comment:nil parentWindow:[self window] whenDone:^(NSURL *url, NSString *comment) {
		if(url) {
			// set the URL
			[super willChangeValueForKey:@"urlstring"];
			[self setUrl:url];
			[super didChangeValueForKey:@"urlstring"];

			// TODO: deal with the comment

			// save URL
			[[NSUserDefaults standardUserDefaults] setObject:[[self url] absoluteString] forKey:@"url"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}];
}

-(IBAction)doCreateFileURL:(id)sender {
	NSURL* defaultURL = [PGDialogWindow defaultFileURL];
	[[self dialog] beginConnectionSheetWithURL:defaultURL comment:nil parentWindow:[self window] whenDone:^(NSURL *url, NSString *comment) {
		if(url) {
			// set the URL
			[super willChangeValueForKey:@"urlstring"];
			[self setUrl:url];
			[super didChangeValueForKey:@"urlstring"];

			// TODO: deal with the comment

			// save URL
			[[NSUserDefaults standardUserDefaults] setObject:[[self url] absoluteString] forKey:@"url"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}];
}

-(IBAction)doEditURL:(id)sender {
	[[self dialog] beginConnectionSheetWithURL:[self url] comment:nil parentWindow:[self window] whenDone:^(NSURL *url, NSString *comment) {
		if(url) {
			// set the URL
			[super willChangeValueForKey:@"urlstring"];
			[self setUrl:url];
			[super didChangeValueForKey:@"urlstring"];

			// TODO: deal with the comment

			// save URL
			[[NSUserDefaults standardUserDefaults] setObject:[[self url] absoluteString] forKey:@"url"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}];
}


-(IBAction)doCreateRoleWindow:(id)sender {
	[[self dialog] beginRoleSheetWithParameters:nil connection:[self connection] parentWindow:[self window] whenDone:^(PGQuery *query) {
		if(query) {
			[self execute:query];
		}
	}];
}

-(IBAction)doCreateSchemaWindow:(id)sender {
	[[self dialog] beginSchemaSheetWithParameters:nil connection:[self connection] parentWindow:[self window] whenDone:^(PGQuery *query) {
		if(query) {
			[self execute:query];
		}
	}];
}

-(IBAction)doCreateDatabaseWindow:(id)sender {
	[[self dialog] beginDatabaseSheetWithParameters:nil connection:[self connection] parentWindow:[self window] whenDone:^(PGQuery *query) {
		if(query) {
			[self execute:query];
		}
	}];
}

-(IBAction)doLogin:(id)sender {
	if([self url]==nil) {
		return;
	}
	[[self connection] connectWithURL:[self url] whenDone:^(BOOL usedPassword, NSError* error) {
		if(error) {
			[self handleLoginError:error];
			return;
		}
		if(usedPassword) {
			NSString* password = [[self passwordstore] passwordForURL:[self url]];
			if(password) {
				// TODO: don't save to keychain if user doesn't want it
				[[self passwordstore] setPassword:password forURL:[self url] saveToKeychain:YES];
			}
		}
	}];
}

-(IBAction)doLogout:(id)sender {
	[[self connection] disconnect];
}

-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary {
	NSString* password = [[self passwordstore] passwordForURL:[NSURL URLWithPostgresqlParams:dictionary]];
	if(password) {
		[dictionary setObject:password forKey:@"password"];
	}
}

-(void)connection:(PGConnection *)connection error:(NSError *)error {
	NSLog(@"ERROR: %@",error);
}

-(void)connection:(PGConnection *)connection statusChange:(PGConnectionStatus)status description:(NSString *)description {
	if(status==PGConnectionStatusConnected) {
		[self setConnected:YES];
		[self setDisconnected:NO];
	} else if(status==PGConnectionStatusDisconnected) {
		[self setDisconnected:YES];
		[self setConnected:NO];
	} else {
		[self setDisconnected:NO];
		[self setConnected:NO];
	}
	NSLog(@"status = %@",description);
}

@end
