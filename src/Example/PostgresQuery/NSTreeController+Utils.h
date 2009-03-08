
#import <Cocoa/Cocoa.h>

@interface NSTreeController (Utils)
-(void)setSelectedObjects:(NSArray *)newSelectedObjects;
-(NSIndexPath *)indexPathToObject:(id)object;
@end
