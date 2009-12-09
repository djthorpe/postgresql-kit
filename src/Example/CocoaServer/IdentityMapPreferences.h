
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import "AppDelegate.h"
#import "IdentityGroupArrayController.h"
#import "IdentityUserArrayController.h"

@interface IdentityMapPreferences : NSObject {
	NSWindow* ibMainWindow;
	NSWindow* ibIdentityMapWindow;
	AppDelegate* ibAppDelegate;
	IdentityGroupArrayController* ibGroupsArrayController;
	IdentityUserArrayController* ibIdentityArrayController;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* ibMainWindow;
@property (assign) IBOutlet NSWindow* ibIdentityMapWindow;
@property (assign) IBOutlet AppDelegate* ibAppDelegate;
@property (assign) IBOutlet IdentityGroupArrayController* ibGroupsArrayController;
@property (assign) IBOutlet IdentityUserArrayController* ibIdentityArrayController;

// properties
@property (readonly) FLXPostgresServer* server;

// IB Actions
-(IBAction)doIdentityMap:(id)sender;
-(IBAction)doButton:(id)sender;

@end
