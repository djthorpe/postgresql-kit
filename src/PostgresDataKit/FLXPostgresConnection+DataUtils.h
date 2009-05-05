
@interface FLXPostgresConnection (DataUtils)
-(NSObject* )insertRowForObject:(FLXPostgresDataObject* )theObject full:(BOOL)isFullCommit;
-(void)updateRowForObject:(FLXPostgresDataObject* )theObject full:(BOOL)isFullCommit;
-(void)deleteRowForObject:(FLXPostgresDataObject* )theObject;
@end
