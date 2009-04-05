
#import <Foundation/Foundation.h>

// helper function for constructing arrays

@interface FLXPostgresArray : NSObject {
	FLXPostgresType type;
	NSUInteger dimensions;
	NSUInteger* size;
	NSUInteger* lowerBound;
	NSUInteger numberOfTuples;
	NSMutableArray* tuples;
}

@property (retain) NSMutableArray* tuples;
@property (assign) FLXPostgresType type;
@property (assign) NSUInteger dimensions;
@property (assign) NSUInteger numberOfTuples;
@property (assign) NSUInteger* size;
@property (assign) NSUInteger* lowerBound;

+(FLXPostgresArray* )arrayWithDimensions:(NSUInteger)theDimensions type:(FLXPostgresType)theType;

// methods
-(void)setDimension:(NSUInteger)theDimension size:(NSUInteger)theSize lowerBound:(NSUInteger)theLowerBound;
-(void)addTuple:(NSObject* )theObject;
-(NSArray* )array;

@end
