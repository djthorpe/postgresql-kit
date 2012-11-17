
@interface FLXPostgresServer (Access)

-(NSArray* )readAccessTuples;
-(NSArray* )readIdentityTuples;
-(BOOL)writeAccessTuples:(NSArray* )theArray;

@end
