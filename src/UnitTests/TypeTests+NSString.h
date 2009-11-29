#import <SenTestingKit/SenTestingKit.h>
#import <PostgresClientKit/PostgresClientKit.h>

@interface TypeTests : SenTestCase {
	FLXPostgresConnection* server;
}

@property (retain) FLXPostgresConnection* server;

@end
