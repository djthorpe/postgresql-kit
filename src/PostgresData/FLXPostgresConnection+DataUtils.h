
@interface FLXPostgresConnection (DataUtils)
-(NSObject* )insertRowForTable:(NSString* )theTable values:(NSArray* )theValues columns:(NSArray* )theColumns primaryKey:(NSString* )thePrimaryKey inSchema:(NSString* )theSchema;
-(void)updateRowForTable:(NSString* )theTable values:(NSArray* )theValues columns:(NSArray* )theColumns primaryKey:(NSString* )thePrimaryKey primaryValue:(NSObject* )thePrimaryValue inSchema:(NSString* )theSchema;
-(void)deleteRowForTable:(NSString* )theTable primaryKey:(NSString* )thePrimaryKey primaryValue:(NSObject* )thePrimaryValue inSchema:(NSString* )theSchema;
@end
