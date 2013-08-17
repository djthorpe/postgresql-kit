
#import <Cocoa/Cocoa.h>

@interface SocketWindowController : NSWindowController {
	NSUInteger _port;
	BOOL _defaultPort;
	NSString* _path;
	NSString* _username;
	NSString* _database;
}

// properties
@property NSUInteger port;
@property NSString* path;
@property (readonly) NSString* displayedPath;
@property NSString* username;
@property NSString* database;
@property BOOL defaultPort;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow;

// ibactions
-(IBAction)ibEndSheetForButton:(id)sender;
-(IBAction)ibDoChooseFolder:(id)sender;

@end
