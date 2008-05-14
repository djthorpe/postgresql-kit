
#import <Cocoa/Cocoa.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import "ServerController.h"
#import "CreateDropDatabaseController.h"

@interface Controller : NSObject {
	// properties
	FLXPostgresConnection* m_theConnection;
	NSTimer* m_theTimer;
	NSUInteger m_theSelectedDatabase;
	NSIndexSet* m_theSelectedDatabases;
	
	// IBOutlets
	IBOutlet CreateDropDatabaseController* m_theCreateDropDatabaseController;
	IBOutlet ServerController* m_theServerController;
	IBOutlet NSWindow* m_theWindow;	
	IBOutlet NSSplitView* m_theSplitView;
	IBOutlet NSView* m_theResizeView;
	IBOutlet NSArrayController* m_theDatabases;
}

// actions
-(IBAction)doCreateDatabase:(id)sender;
-(IBAction)doDropDatabase:(id)sender;

@end
