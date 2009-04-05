

#import <objc/runtime.h>

@interface FLXPostgresDataObject (Private)
-(id)initWithContext:(FLXPostgresDataObjectContext* )theContext;
-(void)commit;
-(void)rollback;
@end
