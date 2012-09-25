
#import <Cocoa/Cocoa.h>

@interface ConnectionPrefs : NSObject

@property id delegate;

@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSTextField* ibCustomPort;

@property BOOL allowRemoteConnections;
@property BOOL portEditable;
@property BOOL customPortEditable;
@property NSUInteger selectedPortOption;
@property NSString* portField;
@property NSString* lastPortField;

@property (readonly) NSString* hostname;
@property (readonly) NSUInteger port;

-(IBAction)ibToolbarConnectionSheetOpen:(NSWindow* )window delegate:(id)sender;

@end

@interface NSObject (ConnectionPrefsDelegate)
-(void)restartServer;
@end
