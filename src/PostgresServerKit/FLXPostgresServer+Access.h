
@interface FLXPostgresServer (Access)

-(NSArray* )readAccessTuples;
-(BOOL)writeAccessTuples:(NSArray* )theArray;

@end
