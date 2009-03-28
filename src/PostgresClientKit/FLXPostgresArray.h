
#import <Foundation/Foundation.h>

// helper function for constructing arrays

@interface FLXPostgresArray : NSObject {
	FLXPostgresOid type;
	NSMutableArray* tuples;
}

@property (retain) NSMutableArray* tuples;
@property (assign) FLXPostgresOid type;

+(FLXPostgresArray* )arrayWithType:(FLXPostgresOid)theType;

// methods
-(void)setDimension:(NSUInteger)theDimension size:(NSUInteger)theSize lowerBound:(NSUInteger)theLowerBound;
-(void)setTuple:(NSUInteger)theTuple object:(NSObject* )theObject;
-(NSArray* )array;

@end
