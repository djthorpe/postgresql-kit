
#import <Cocoa/Cocoa.h>

@interface PGSplitViewController : NSViewController <NSSplitViewDelegate>

// methods
-(BOOL)setLeftView:(id)viewOrController;
-(BOOL)setRightView:(id)viewOrController;

@end
