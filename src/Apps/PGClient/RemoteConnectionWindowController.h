
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>

@interface RemoteConnectionWindowController : NSWindowController {
	PGConnection* _connection;
}

// properties
@property NSUInteger port;
@property NSString* hostname;
@property NSString* username;
@property NSString* database;
@property NSUInteger timeout;
@property NSString* applicationName;
@property BOOL defaultPort;
@property BOOL requireEncryption;
@property BOOL showAdvancedOptions;
@property BOOL validParameters;
@property NSString* timeoutString;
@property NSImage* statusImage;
@property (assign) IBOutlet NSBox* ibAdvancedOptionsBox;
@property (readonly) NSURL* url;
@property NSTimer* pingTimer;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow;

// ibactions
-(IBAction)ibEndSheetForButton:(id)sender;

@end
