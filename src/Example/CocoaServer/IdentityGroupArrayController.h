
#import <Cocoa/Cocoa.h>

@interface IdentityGroupArrayController : NSArrayController {
	NSTableView* ibTableView;
}

@property (assign) IBOutlet NSTableView* ibTableView;
@property (readonly) NSString* selectedGroup;

@end
