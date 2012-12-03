
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>

@interface Application : NSObject <NSTableViewDataSource> {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSTableView* _tableView;
}

@property (readwrite) PGServerHostAccess* hostAccessRules;
@property (readonly) BOOL modified;
@property BOOL saveEnabled;
@property NSString* windowPath;

// methods
-(IBAction)ibFileOpen:(id)sender;
-(IBAction)ibFileSave:(id)sender;
-(IBAction)ibFileRevert:(id)sender;


@end
