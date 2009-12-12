
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import "AppDelegate.h"

@interface BackupPreferences : NSObject {
	NSWindow* ibMainWindow;
	NSWindow* ibBackupWindow;
	AppDelegate* ibAppDelegate;
	NSString* backupPath;
	double frequency;
	NSString* frequencyAsString;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* ibMainWindow;
@property (assign) IBOutlet NSWindow* ibBackupWindow;
@property (assign) IBOutlet AppDelegate* ibAppDelegate;

// properties
@property (readonly) FLXPostgresServer* server;
@property (retain) NSString* frequencyAsString;
@property (assign) double frequency;
@property (retain) NSString* backupPath;

// IB Actions
-(IBAction)doBackup:(id)sender;
-(IBAction)doButton:(id)sender;
-(IBAction)doBackupPath:(id)sender;

@end
