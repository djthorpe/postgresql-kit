
#import "AppPreferences.h"

@implementation AppPreferences

////////////////////////////////////////////////////////////////////////////////
// load and save user defaults

-(void)loadUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[self setAutoHideWindow:[defaults boolForKey:@"autoHideWindow"]];
	[self setAutoStartServer:[defaults boolForKey:@"autoStartServer"]];
	[self setStatusRefreshInterval:[defaults floatForKey:@"statusRefreshInterval"]];

	// set defaults
	if([self statusRefreshInterval] <= 0.0) {
		[self setStatusRefreshInterval:5.0];
		[self saveUserDefaults];
	}
}

-(void)saveUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[self autoHideWindow] forKey:@"autoHideWindow"];
	[defaults setBool:[self autoStartServer] forKey:@"autoStartServer"];
	[defaults synchronize];
}

////////////////////////////////////////////////////////////////////////////////
// init method

-(void)awakeFromNib {
	[self loadUserDefaults];
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibPreferencesStart:(id)sender {
	[NSApp beginSheet:_preferencesSheet modalForWindow:_mainWindow modalDelegate:self didEndSelector:@selector(ibPreferencesSheetEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibPreferencesEnd:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
}

-(IBAction)ibPreferencesSheetEnd:(NSWindow* )sheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	[sheet orderOut:self];
	[self saveUserDefaults];
}

@end
