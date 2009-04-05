

#import <Foundation/NSObjCRuntime.h>

@interface FLXPostgresDataObject (Private)
-(id)initWithContext:(FLXPostgresDataObjectContext* )theContext;
-(void)commit;
-(void)rollback;
@end
