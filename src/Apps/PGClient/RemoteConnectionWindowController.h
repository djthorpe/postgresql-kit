
#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>

@interface RemoteConnectionWindowController : NSWindowController {
	PGConnection* _connection;
	NSMutableDictionary* _parameters;
}

// properties
@property (readonly) NSMutableDictionary* parameters;

@property NSString* portString;
@property NSString* hostname;
@property NSString* username;
@property NSString* database;
@property NSUInteger timeout;
@property NSString* applicationName;
@property BOOL defaultPort;
@property BOOL requireEncryption;
@property BOOL showAdvancedOptions;
@property BOOL validParameters;
@property (readonly) NSString* timeoutString;
@property NSImage* statusImage;
@property (readonly) NSUInteger port;
@property (readonly) NSURL* url;
@property (assign) IBOutlet NSBox* ibAdvancedOptionsBox;
@property NSTimer* pingTimer;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow url:(NSURL* )url;

// ibactions
-(IBAction)ibEndSheetForButton:(id)sender;

@end
