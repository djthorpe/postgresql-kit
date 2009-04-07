

#import <objc/runtime.h>

@interface FLXPostgresDataObject (Private)
-(id)initWithContext:(FLXPostgresDataObjectContext* )theContext;
-(NSArray* )_modifiedTableColumns;
-(BOOL)_isNewObject;
-(void)_commit;
-(void)_rollback;
@end

@interface FLXPostgresDataCache (Private)
-(FLXPostgresDataObjectContext* )objectContextForClass:(Class)theClass;
@end
