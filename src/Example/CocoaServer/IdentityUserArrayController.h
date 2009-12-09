
#import <Cocoa/Cocoa.h>
#import "IdentityGroupArrayController.h"

@interface IdentityUserArrayController : NSArrayController {
	NSTableView* ibTableView;
	IdentityGroupArrayController* ibGroupsArrayController;
}

@property (assign) IBOutlet NSTableView* ibTableView;
@property (assign) IBOutlet IdentityGroupArrayController* ibGroupsArrayController;

@end
