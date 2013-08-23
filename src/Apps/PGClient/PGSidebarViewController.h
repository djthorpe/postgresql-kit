
#import <Cocoa/Cocoa.h>
#import "PGSidebarDataSource.h"

@interface PGSidebarViewController : NSViewController <NSOutlineViewDelegate> {
	PGSidebarDataSource* _datasource;
}

// properties
@property (readonly) PGSidebarDataSource* datasource;

// methods
-(void)applicationDidFinishLaunching:(NSNotification* )aNotification;
//-(void)setStatus:(PGSidebarNodeStatusType)status forNode:(PGSidebarNode* )node;

// ibactions
-(IBAction)doOpen:(id)sender;
-(IBAction)doClose:(id)sender;

@end
