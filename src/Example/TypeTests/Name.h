
#import <PostgresDataKit/PostgresDataKit.h>

@interface Name : FLXPostgresDataObject {

}

@property (assign) NSInteger id;
@property (retain) NSString* name;
@property (retain) NSString* email;
@property (assign) BOOL male;

@end
