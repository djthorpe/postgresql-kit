
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresArray

////////////////////////////////////////////////////////////////////////////////

@synthesize type;
@synthesize tuples;
@synthesize dimensions;
@synthesize size;
@synthesize lowerBound;
@synthesize numberOfTuples;

////////////////////////////////////////////////////////////////////////////////

-(id)initWithDimensions:(NSUInteger)theDimensions type:(FLXPostgresOid)theType {
	self = [super init];
	if (self != nil) {
		[self setType:theType];
		[self setDimensions:theDimensions];		
		[self setTuples:[[NSMutableArray array] retain]];
		if(theDimensions > 0) {
			[self setSize:malloc(sizeof(NSUInteger) * theDimensions)];
			NSParameterAssert([self size]);			
			[self setLowerBound:malloc(sizeof(NSUInteger) * theDimensions)];
			NSParameterAssert([self lowerBound]);			
		}
	}
	return self;
}

-(void)dealloc {
	[self setTuples:nil];
	free([self size]);
	free([self lowerBound]);
	[super dealloc];
}

+(FLXPostgresArray* )arrayWithDimensions:(NSUInteger)theDimensions type:(FLXPostgresOid)theType {
	return [[[FLXPostgresArray alloc] initWithDimensions:theDimensions type:theType] autorelease];
}

////////////////////////////////////////////////////////////////////////////////

-(void)setDimension:(NSUInteger)theDimension size:(NSUInteger)theSize lowerBound:(NSUInteger)theLowerBound {
	NSParameterAssert(theSize > 0);
	NSParameterAssert(theDimension < [self dimensions]);

	// set the size and lower bound for this dimension
	size[theDimension] = theSize;
	lowerBound[theDimension] = theLowerBound;

	// compute the number of tuples
	if(theDimension==0) {
		[self setNumberOfTuples:theSize];
	} else {
		[self setNumberOfTuples:([self numberOfTuples] * theSize)];
	}		
}

-(void)addTuple:(NSObject* )theObject {
	NSParameterAssert(theObject);
	NSParameterAssert([[self tuples] count] < [self numberOfTuples]);
	[[self tuples] addObject:theObject];
}

-(NSArray* )array {
	// check for empty array
	if([self dimensions]==0) {
		return [NSArray array];
	}
	// check for single-dimension array
	if([self dimensions]==1) {
		return [NSArray arrayWithArray:[self tuples]];
	}
	// TODO - other dimensions
	return [self tuples];
}

@end
