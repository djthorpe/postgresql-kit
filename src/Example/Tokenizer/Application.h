
#import <Cocoa/Cocoa.h>
#import <PGServerKit/PGServerKit.h>

@interface Application : NSObject <NSTableViewDataSource, NSSplitViewDelegate> {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSTableView* _tableView;
	IBOutlet NSSplitView* _splitView;
	IBOutlet NSImageView* _resizeView;
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
