
#import "Application.h"

@implementation Application

-(void)awakeFromNib {
	NSLog(@"awake from nib");
}

-(IBAction)ibFileOpen:(id)sender {
	// open the sheet which allows you to select a pg_hba.conf file
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel beginSheetModalForWindow:_mainWindow completionHandler:^(NSInteger returnCode) {
		if(returnCode==NSOKButton) {
			BOOL isSuccess = [self load:[panel URL]];
			if(isSuccess==NO) {
				NSLog(@"error!");
			} else {
				NSLog(@"success!");
			}
		}
    }];

}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	// do nothing
}

////////////////////////////////////////////////////////////////////////////////

-(BOOL)load:(NSURL* )url {
	PGServerHostAccess* hostAccessRules = [[PGServerHostAccess alloc] initWithPath:[url path]];
	if(hostAccessRules==nil) {
		return NO;
	}
	// load the host access rules
	if([hostAccessRules load]==NO) {
		return NO;
	}
	// set host access rules
	[self setHostAccessRules:hostAccessRules];
	// return success
	return YES;
}

@end
