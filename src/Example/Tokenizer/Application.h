
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>

@interface Application : NSObject <NSTableViewDataSource> {
	IBOutlet NSWindow* _mainWindow;
}

@property (readwrite) PGServerHostAccess* hostAccessRules;

@end
