
#import "Token.h"

@implementation Token
-(id)initWithString:(NSString* )string {
	self = [super init];
	if(self) {
		[self setString:string];
		NSLog(@"alloc string: <%@>",[self string]);
	}
	return self;
}
@end
