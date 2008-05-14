
#import <Foundation/Foundation.h>

typedef enum {
  FLXPostgresTypeUnknown  = -1,
  FLXPostgresTypeString   = 0,
  FLXPostgresTypeInteger  = 1,
  FLXPostgresTypeReal     = 2,
  FLXPostgresTypeBool     = 3,
  FLXPostgresTypeData     = 4,
  FLXPostgresTypeDate     = 5,
  FLXPostgresTypeDatetime = 6
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
