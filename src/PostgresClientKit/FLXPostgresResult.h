
#import <Foundation/Foundation.h>

@interface FLXPostgresResult : NSObject {
	void* m_theResult;
	NSString* m_theAffectedRows;
	NSUInteger m_theNumberOfRows;
	NSUInteger m_theNumberOfColumns;
	NSUInteger m_theRow;
	FLXPostgresConnection* m_theConnection;
	void** m_theTypeHandlers;
}

@property (readonly) NSUInteger numberOfColumns;
@property (readonly) NSUInteger affectedRows;

// properties
-(BOOL)isDataReturned;

// properties - columns
-(NSUInteger)numberOfColumns;
-(NSArray* )columns;
-(NSInteger)modifierForColumn:(NSUInteger)theColumn;
-(NSUInteger)sizeForColumn:(NSUInteger)theColumn;

// methods
-(void)dataSeek:(NSUInteger)theRow;
-(NSArray* )fetchRowAsArray;

@end
