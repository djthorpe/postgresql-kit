//
//  AppDelegate.h
//  PGServer
//
//  Created by David Thorpe on 02/09/2012.
//
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property BOOL startButtonEnabled;
@property BOOL stopButtonEnabled;
@property BOOL reloadButtonEnabled;
@property NSString* message;

@end
