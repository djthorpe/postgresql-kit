
#import <Cocoa/Cocoa.h>

@interface ConnectionPrefs : NSObject

@property id delegate;
@property (assign) BOOL enabled;
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

-(IBAction)ibSheetOpen:(NSWindow* )window delegate:(id)sender;

@end
