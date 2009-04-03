
@interface FLXPostgresConnection (Utils)

-(NSArray* )databases;
-(NSArray* )schemas;
-(NSArray* )tablesInSchema:(NSString* )theSchema;
-(NSString* )primaryKeyForTable:(NSString* )theTable inSchema:(NSString* )theSchema;
-(NSArray* )columnNamesForTable:(NSString* )theTable inSchema:(NSString* )theSchema;
@end
