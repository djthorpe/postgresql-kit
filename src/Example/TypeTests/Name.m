
#import "Name.h"

@implementation Name

@synthesize name;
@synthesize email;
@synthesize male;

////////////////////////////////////////////////////////////////////////////////

-(void)awakeFromInsert {
	[super awakeFromInsert];
	[self setMale:YES];	
}

-(void)dealloc {
	[self setName:nil];
	[self setEmail:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

@end
