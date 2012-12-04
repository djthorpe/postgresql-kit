
#import <Foundation/Foundation.h>

@interface FLXPostgresConnectSetting : NSObject {
	NSNetService* netService;
	NSString* name;
	NSString* host;
	NSUInteger port;
	NSString* database;
	NSString* user;
	NSString* password;
}

@property (retain) NSNetService* netService;
@property (retain) NSString* name;
@property (retain) NSString* host;
@property (assign) NSUInteger port;
@property (retain) NSString* database;
@property (retain) NSString* user;
@property (retain) NSString* password;

+(FLXPostgresConnectSetting* )settingWithNetService:(NSNetService* )theService;

@end
