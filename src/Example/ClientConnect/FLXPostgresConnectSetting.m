
#import "FLXPostgresConnectSetting.h"

@implementation FLXPostgresConnectSetting

@synthesize name;
@synthesize host;
@synthesize port;
@synthesize database;
@synthesize user;
@synthesize password;

-(void)dealloc {
	[self setName:nil];
	[self setHost:nil];
	[self setDatabase:nil];
	[self setUser:nil];
	[self setPassword:nil];
	[super dealloc];
}

+(FLXPostgresConnectSetting* )settingWithNetService:(NSNetService* )theService {
	FLXPostgresConnectSetting* theObject = [[[FLXPostgresConnectSetting alloc] init] autorelease];
	
	[theObject setName:[theService name]];
	[theObject setPort:[theService port]];
	[theObject setHost:[theService hostName]];
	
	return theObject;
}

@end
