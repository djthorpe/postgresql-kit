

#import <objc/runtime.h>

@interface FLXPostgresDataObject (Private)
-(id)initWithContext:(FLXPostgresDataObjectContext* )theContext;
-(void)commit;
-(void)rollback;
@end

@interface FLXPostgresDataCache (Private)
-(FLXPostgresDataObjectContext* )objectContextForClass:(Class)theClass;
@end
