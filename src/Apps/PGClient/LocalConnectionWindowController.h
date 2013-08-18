
#import <Cocoa/Cocoa.h>

@interface LocalConnectionWindowController : NSWindowController {
	NSUInteger _port;
	BOOL _defaultPort;
	NSString* _path;
	NSString* _username;
	NSString* _database;
	BOOL _validParameters;
}

// properties
@property NSUInteger port;
@property NSString* path;
@property NSString* username;
@property NSString* database;
@property BOOL defaultPort;
@property (readonly) NSString* displayedPath;
@property (readonly) BOOL validParameters;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow;

// ibactions
-(IBAction)ibEndSheetForButton:(id)sender;
-(IBAction)ibDoChooseFolder:(id)sender;

@end
