
#import "IdentityMapPreferences.h"

@implementation IdentityMapPreferences

////////////////////////////////////////////////////////////////////////////////

@synthesize ibMainWindow;
@synthesize ibIdentityMapWindow;
@synthesize ibAppDelegate;
@dynamic server;

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresServer* )server {
	return [FLXPostgresServer sharedServer];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)identityMapDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];	
	
	if(returnCode==NSOKButton) {
		NSLog(@"TODO: Write identity map");
	}
}

////////////////////////////////////////////////////////////////////////////////

-(IBAction)doIdentityMap:(id)sender {	
	// begin display	
	[NSApp beginSheet:[self ibIdentityMapWindow] modalForWindow:[self ibMainWindow] modalDelegate:self didEndSelector:@selector(identityMapDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)doButton:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	
	if([[theButton title] isEqual:@"OK"]) {
		[NSApp endSheet:[self ibIdentityMapWindow] returnCode:NSOKButton];
	} else {
		[NSApp endSheet:[self ibIdentityMapWindow] returnCode:NSCancelButton];
	}
}

@end
