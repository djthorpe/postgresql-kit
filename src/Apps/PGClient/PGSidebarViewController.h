
#import <Cocoa/Cocoa.h>
#import "PGSidebarDataSource.h"

@interface PGSidebarViewController : NSViewController <NSOutlineViewDelegate> {
	PGSidebarDataSource* _datasource;
}

// properties
@property (readonly) PGSidebarDataSource* datasource;
@property (readonly) BOOL canOpen;
@property (readonly) BOOL canClose;
@property (readonly) BOOL canDelete;

// application delegate methods
-(void)applicationDidFinishLaunching:(NSNotification* )aNotification;
-(void)applicationWillTerminate:(id)sender;

// methods
-(PGSidebarNode* )nodeForKey:(NSUInteger)key;
-(PGSidebarNode* )selectedNode;
-(void)selectNode:(PGSidebarNode* )node;
-(void)deleteNode:(PGSidebarNode* )node;
-(void)setNode:(PGSidebarNode* )node status:(PGSidebarNodeStatusType)status;
-(void)expandNodeWithKey:(NSUInteger)key;

// load and save to user defaults
-(BOOL)loadFromUserDefaults;
-(BOOL)saveToUserDefaults;

// select database
-(PGSidebarNode* )selectDatabaseNodeWithName:(NSString* )name serverWithKey:(NSUInteger)key;

// ibactions
-(IBAction)doOpen:(id)sender;
-(IBAction)doClose:(id)sender;
-(IBAction)doDelete:(id)sender;
-(IBAction)doDoubleClick:(id)sender;

@end
