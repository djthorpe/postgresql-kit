
#import <Foundation/Foundation.h>

@interface PGSourceViewNode : NSObject {
	NSString* _name;
}

// constructors
-(id)initWithName:(NSString* )name;

// methods
-(BOOL)isGroupItem;
-(BOOL)shouldSelectItem;

@end
