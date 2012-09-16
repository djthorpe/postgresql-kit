
#import <Cocoa/Cocoa.h>

@interface ConnectionPrefs : NSObject

@property (assign) IBOutlet NSPanel* ibWindow;
@property BOOL allowRemoteConnections;
@property BOOL customPortEnabled;
@property BOOL customPortEditable;
@property NSUInteger selectedPortOption;

@property (readonly) NSString* hostname;
@property NSUInteger port;

-(IBAction)ibToolbarConnectionSheetOpen:(NSWindow* )sender;

@end
