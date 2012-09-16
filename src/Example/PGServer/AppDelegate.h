//
//  AppDelegate.h
//  PGServer
//
//  Created by David Thorpe on 02/09/2012.
//
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow* ibWindow;
@property (assign) IBOutlet NSPanel* ibHostAccessWindow;
@property (assign) IBOutlet NSTextView* ibLogTextView;
@property BOOL ibStartButtonEnabled;
@property BOOL ibStopButtonEnabled;
@property BOOL ibBackupButtonEnabled;
@property NSImage* ibServerStatusIcon;
@property NSString* ibServerVersion;


@end
