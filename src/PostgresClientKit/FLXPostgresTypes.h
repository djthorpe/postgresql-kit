
#import <Foundation/Foundation.h>

typedef enum {
  FLXPostgresTypeUnknown  = -1,
  FLXPostgresTypeString   = 1,
  FLXPostgresTypeInteger  = 2, // int1, int2 and int4
  FLXPostgresTypeReal     = 3,
  FLXPostgresTypeBool     = 5,
  FLXPostgresTypeData     = 6,
  FLXPostgresTypeDate     = 7,
  FLXPostgresTypeDatetime = 8
} FLXPostgresType;

@interface FLXPostgresTypes : NSObject {
  NSMutableDictionary* m_theDictionary;
  NSMutableDictionary* m_theReverseDictionary;  
}

// constructor
+(FLXPostgresTypes* )array;

// get type properties
-(NSString* )stringAtIndex:(NSUInteger)theIndex;
-(FLXPostgresType)typeAtIndex:(NSUInteger)theIndex;
-(NSUInteger)indexForType:(FLXPostgresType)theType;

// set type properties
-(void)insertString:(NSString* )theType atIndex:(NSUInteger)theIndex;

@end
