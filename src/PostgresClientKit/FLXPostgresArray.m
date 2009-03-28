
#import "FLXPostgresArray.h"

@implementation FLXPostgresArray

////////////////////////////////////////////////////////////////////////////////

@synthesize type;
@synthesize tuples;

////////////////////////////////////////////////////////////////////////////////

-(id)initWithType:(FLXPostgresOid)theType {
	self = [super init];
	if (self != nil) {
		[self setType:theType];
		[self setTuples:[[NSMutableArray array] retain]];
	}
	return self;
}

-(void)dealloc {
	[self setTuples:nil];
	[super dealloc];
}

+(FLXPostgresArray* )arrayWithType:(FLXPostgresOid)theType {
	return [[[FLXPostgresArray alloc] initWithType:theType] autorelease];
}	

////////////////////////////////////////////////////////////////////////////////

-(void)setDimension:(NSUInteger)theDimension size:(NSUInteger)theSize lowerBound:(NSUInteger)theLowerBound;
-(void)setTuple:(NSUInteger)theTuple object:(NSObject* )theObject;
-(NSArray* )array;


@end
