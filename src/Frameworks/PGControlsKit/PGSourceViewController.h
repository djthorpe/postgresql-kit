
#import <Cocoa/Cocoa.h>

@interface PGSourceViewController : NSViewController <NSOutlineViewDelegate,NSOutlineViewDataSource> {
	NSMutableArray* _headings;
}

// methods
-(void)addHeadingWithTitle:(NSString* )title;

@end
