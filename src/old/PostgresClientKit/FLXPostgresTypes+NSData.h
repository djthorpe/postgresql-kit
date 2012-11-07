
@interface FLXPostgresTypes (NSData)

-(NSObject* )boundValueFromData:(NSData* )theData type:(FLXPostgresOid* )theType;
-(FLXPostgresOid)boundTypeFromData:(NSData* )theData;
-(NSString* )quotedStringFromData:(NSData* )theData;
-(NSObject* )dataObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength;

@end
