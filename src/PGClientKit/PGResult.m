
#import "PGClientKit.h"
#import "PGClientKit+Private.h"

@implementation PGResult

////////////////////////////////////////////////////////////////////////////////
// initialization

-(id)init {
	return nil;
}

-(id)initWithResult:(PGresult* )theResult {
	self = [super init];
	if(self) {
		NSParameterAssert(theResult);
		_result = theResult;
	}
	return self;	
}

-(void)dealloc {
	PQclear((PGresult* )_result);
}

@end
