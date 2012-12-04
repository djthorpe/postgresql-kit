
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import "AppDelegate.h"

@interface BackupPreferences : NSObject {
	// IBOutlets
	NSWindow* ibMainWindow;
	NSWindow* ibBackupWindow;
	AppDelegate* ibAppDelegate;

	// values from backup settings
	NSString* backupPath;
	NSTimeInterval backupFrequency;
	NSUInteger backupThinKeepHours;
	NSUInteger backupThinKeepDays;
	NSUInteger backupThinKeepWeeks;
	NSUInteger backupThinKeepMonths;
	
	// temporary values
	double frequencySliderValue;
	NSString* frequencySliderString;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* ibMainWindow;
@property (assign) IBOutlet NSWindow* ibBackupWindow;
@property (assign) IBOutlet AppDelegate* ibAppDelegate;

// properties
@property (readonly) FLXPostgresServer* server;
@property (retain) NSString* frequencySliderString;
@property (assign) double frequencySliderValue;
@property (retain) NSString* backupPath;
@property (assign) NSTimeInterval backupFrequency;
@property (assign) NSUInteger backupThinKeepHours;
@property (assign) NSUInteger backupThinKeepDays;
@property (assign) NSUInteger backupThinKeepWeeks;
@property (assign) NSUInteger backupThinKeepMonths;

// IB Actions
-(IBAction)doBackup:(id)sender;
-(IBAction)doButton:(id)sender;
-(IBAction)doBackupPath:(id)sender;

@end
