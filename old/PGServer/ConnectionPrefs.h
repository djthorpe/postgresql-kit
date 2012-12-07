
#import <Cocoa/Cocoa.h>
#import "ControllerDelegate.h"

@interface ConnectionPrefs : NSObject

@property id<ControllerDelegate> delegate;
@property (assign) IBOutlet NSWindow* ibWindow;

@property BOOL remoteConnectionValue;
@property BOOL bonjourValue;
@property NSString* portValue;
@property NSString* bonjourServiceValue;
@property BOOL bonjourEnabled;
@property NSUInteger maxConnectionsValue;
@property NSUInteger superConnectionsValue;

@property (readonly) NSUInteger port;
@property (readonly) NSString* hostname;
@property (readonly) NSString* bonjourName;

@property BOOL portEditable;
@property BOOL customPortEditable;
@property NSUInteger selectedPortOption;
@property NSString* portField;
@property NSString* lastPortField;

-(IBAction)ibSheetOpen:(NSWindow* )window delegate:(id)sender;

@end
