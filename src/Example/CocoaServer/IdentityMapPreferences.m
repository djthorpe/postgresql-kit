
#import "IdentityMapPreferences.h"

@implementation IdentityMapPreferences

////////////////////////////////////////////////////////////////////////////////

@synthesize ibMainWindow;
@synthesize ibIdentityMapWindow;
@synthesize ibAppDelegate;
@synthesize ibGroupsArrayController;
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
	// read tuples
	NSArray* theTuples = [[self server] readIdentityTuples];

	// create array of groups
	NSMutableArray* theGroups = [NSMutableArray array];
	for(FLXPostgresServerIdentityTuple* theTuple in theTuples) {
		NSString* theGroup = [theTuple group];
		BOOL isSupergroup = [theTuple isSupergroup];
		if([theGroups containsObject:theGroup]==NO) {
			NSMutableDictionary* theDictionary = [NSMutableDictionary dictionary];
			[theDictionary setObject:theGroup forKey:@"group"];
			[theDictionary setObject:[NSNumber numberWithBool:isSupergroup] forKey:@"isSupergroup"];
			[theDictionary setObject:(isSupergroup ? [NSColor grayColor] : [NSColor blackColor]) forKey:@"textColor"];
			[theGroups addObject:theDictionary];
		}
	}
	
	// add groups to array controller
	[[self ibGroupsArrayController] setContent:theGroups];
	
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
