
#import <PostgresDataKit/PostgresDataKit.h>

@interface Name : FLXPostgresDataObject {	
	NSString* name;
	NSString* email;
	BOOL male;
}

@property (retain) NSString* name;
@property (retain) NSString* email;
@property (assign) BOOL male;

@end
