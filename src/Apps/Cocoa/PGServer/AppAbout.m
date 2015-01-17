
#import "AppAbout.h"

@implementation AppAbout

////////////////////////////////////////////////////////////////////////////////
// init method

-(void)awakeFromNib {
//	[self loadUserDefaults];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic title;
@dynamic notice;

-(NSString* )title {
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* appName = [[bundle infoDictionary] valueForKey:@"CFBundleName"];
	NSString* appVersion = [[bundle infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	NSString* appBuild = [[bundle infoDictionary] valueForKey:(NSString*)kCFBundleVersionKey];
	return [NSString stringWithFormat:@"%@ v%@, build %@",appName,appVersion,appBuild];
}

-(NSAttributedString* )notice {
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* filePath = [bundle pathForResource:@"NOTICE" ofType:@"md"];
	NSDictionary* noticeAttributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
	if(filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		NSString* theString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
		if(theString) {
			return [[NSAttributedString alloc] initWithString:theString attributes:noticeAttributes];
		}
	}
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)ibSheetStart:(id)sender {
	[NSApp beginSheet:_sheetWindow modalForWindow:_mainWindow modalDelegate:self didEndSelector:@selector(ibSheetDidClose:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibSheetEnd:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
}

-(IBAction)ibSheetDidClose:(NSWindow* )sheet returnCode:(NSInteger)returnCode contextInfo:(void* )contextInfo {
	[sheet orderOut:self];
}

@end
