
#import <Foundation/Foundation.h>

@interface FLXPostgresHostAccessTuple : NSObject {
	NSString* type;
	NSString* database;
	NSString* user;
	NSString* address;
	NSString* method;	
	NSString* option;	
	NSString* comment;	
}

@property (retain) NSString* type;
@property (retain) NSString* database;
@property (retain) NSString* user;
@property (retain) NSString* address;
@property (retain) NSString* method;
@property (retain) NSString* option;
@property (retain) NSString* comment;

-(NSString* )stringValue;

@end
