
@interface FLXPostgresConnection (Utils)

-(NSArray* )databases;
-(BOOL)createDatabase:(NSString* )theName;
-(BOOL)databaseExistsWithName:(NSString* )theName;
-(NSArray* )tables;
-(NSArray* )schemas;
-(NSArray* )tablesForSchema:(NSString* )theName;
-(BOOL)tableExistsWithName:(NSString* )theTable inSchema:(NSString* )theSchema;

@end
