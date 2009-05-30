
#import <Foundation/Foundation.h>

@interface FLXPostgresResult : NSObject {
  void* m_theResult;
  NSString* m_theAffectedRows;
  NSUInteger m_theNumberOfRows;
  NSUInteger m_theRow;
  FLXPostgresTypes* m_theTypes;
}

@property (readonly,retain) FLXPostgresTypes* types;

// properties
-(BOOL)isDataReturned;
-(NSUInteger)affectedRows;

// properties - columns and types
-(NSUInteger)numberOfColumns;
-(NSArray* )columns;
-(FLXPostgresType)typeForColumn:(NSUInteger)theColumn;
-(NSInteger)modifierForColumn:(NSUInteger)theColumn;
-(NSUInteger)sizeForColumn:(NSUInteger)theColumn;

// methods
-(void)dataSeek:(NSUInteger)theRow;
-(NSArray* )fetchRowAsArray;

@end
