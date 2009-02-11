
#import "PostgresPrefPaneController.h"

@implementation PostgresPrefPaneController

-(id)initWithBundle:(NSBundle *)bundle {
	self = [super initWithBundle:bundle];
    if(self) {
		NSLog(@"bundle loaded");
	}
	return self;
}

-(void)mainViewDidLoad {
	NSLog(@"loaded view");
}

@end
