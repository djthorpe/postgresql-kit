
#import <Cocoa/Cocoa.h>

@interface RemoteConnectionWindowController : NSWindowController {
	NSUInteger _port;
	BOOL _defaultPort;
	NSString* _hostname;
	NSString* _username;
	NSString* _database;
	BOOL _requireEncryption;
	NSUInteger _timeout;
	BOOL _showAdvancedOptions;
	BOOL _validParameters;
}

// properties
@property NSUInteger port;
@property NSString* hostname;
@property NSString* username;
@property NSString* database;
@property NSUInteger timeout;
@property BOOL defaultPort;
@property BOOL requireEncryption;
@property BOOL showAdvancedOptions;
@property BOOL validParameters;
@property NSString* timeoutString;
@property (assign) IBOutlet NSBox* ibAdvancedOptionsBox;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow;

// ibactions
-(IBAction)ibEndSheetForButton:(id)sender;

@end
