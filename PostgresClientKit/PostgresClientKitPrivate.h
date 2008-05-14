
@interface FLXPostgresResult (Private)
-(PGresult* )result;
@end

@interface FLXPostgresTypes (Private)
// methods for converting from internal postgres binary to NSObjects
+(NSString* )stringFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
+(NSNumber* )integerFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
+(NSNumber* )realFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
+(NSNumber* )booleanFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
+(NSData* )dataFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
+(NSDate* )dateFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
+(NSDate* )timeFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
+(NSDate* )datetimeFromBytes:(const char* )theBytes length:(NSUInteger)theLength;
@end

