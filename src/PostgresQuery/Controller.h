
#import <Cocoa/Cocoa.h>
#import <PostgresClientKit/PostgresClientKit.h>
#import "ServerController.h"
#import "CreateDropDatabaseController.h"
#import "OutlineNode.h"

@interface Controller : NSObject {
	// properties
	FLXPostgresConnection* m_theConnection;
	NSTimer* m_theTimer;
	NSUInteger m_theSelectedDatabase;
	NSIndexSet* m_theSelectedDatabases;
	NSArray* m_theDatabases;
	OutlineNode* m_theTables;
	OutlineNode* m_theSchemas;	
	OutlineNode* m_theQueries;
	
	// IBOutlets
	IBOutlet CreateDropDatabaseController* m_theCreateDropDatabaseController;
	IBOutlet ServerController* m_theServerController;
	IBOutlet NSWindow* m_theWindow;	
	IBOutlet NSSplitView* m_theSplitView;
	IBOutlet NSView* m_theResizeView;
	IBOutlet NSTreeController* m_theOutline;
}

// actions
-(IBAction)doCreateDatabase:(id)sender;
-(IBAction)doDropDatabase:(id)sender;

@end
