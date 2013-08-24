
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

// methods
-(void)applicationDidFinishLaunching:(NSNotification* )aNotification;
//-(void)setStatus:(PGSidebarNodeStatusType)status forNode:(PGSidebarNode* )node;
-(void)deleteNode:(PGSidebarNode* )node;

// ibactions
-(IBAction)doOpen:(id)sender;
-(IBAction)doClose:(id)sender;
-(IBAction)doDelete:(id)sender;

@end
