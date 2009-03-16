
#import "FLXPostgresConnectSetting.h"

@implementation FLXPostgresConnectSetting

@synthesize netService;
@synthesize name;
@synthesize host;
@synthesize port;
@synthesize database;
@synthesize user;
@synthesize password;

-(void)dealloc {
	[self setNetService:nil];
	[self setName:nil];
	[self setHost:nil];
	[self setDatabase:nil];
	[self setUser:nil];
	[self setPassword:nil];
	[super dealloc];
}

+(FLXPostgresConnectSetting* )settingWithNetService:(NSNetService* )theService {
	FLXPostgresConnectSetting* theObject = [[[FLXPostgresConnectSetting alloc] init] autorelease];

	[theObject setNetService:theService];
	[theObject setName:[theService name]];
	[theObject setPort:[theService port]];
	[theObject setHost:[theService hostName]];
	
	return theObject;
}

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@>",[self name]];
}

-(BOOL)isEqual:(id)otherSetting {
	return [[otherSetting netService] isEqualTo:[self netService]];
}

@end
