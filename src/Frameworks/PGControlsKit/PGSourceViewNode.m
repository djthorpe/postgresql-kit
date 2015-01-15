
#import <PGControlsKit/PGControlsKit.h>

@interface PGSourceViewNode ()
@property (retain) NSString* name;
@end

@implementation PGSourceViewNode

-(id)init {
	return nil;
}

-(id)initWithName:(NSString* )name {
	self = [super init];
	if(self) {
		_name = name;
	}
	return self;
}

@synthesize name = _name;

-(BOOL)isGroupItem {
	return YES;
}

-(BOOL)shouldSelectItem {
	return YES;
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ %@>",NSStringFromClass([self class]),[self name]];
}

@end
