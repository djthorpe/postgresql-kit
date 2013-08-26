
#import <Cocoa/Cocoa.h>

@interface RemoteConnectionWindowController : NSWindowController {
	NSUInteger _port;
	BOOL _defaultPort;
	NSString* _hostname;
	NSString* _username;
	NSString* _database;
	BOOL _requireEncryption;
	BOOL _showAdvancedOptions;
}

// properties
@property NSUInteger port;
@property NSString* hostname;
@property NSString* username;
@property NSString* database;
@property BOOL defaultPort;
@property BOOL requireEncryption;
@property BOOL showAdvancedOptions;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow;

// ibactions
-(IBAction)ibEndSheetForButton:(id)sender;

@end
