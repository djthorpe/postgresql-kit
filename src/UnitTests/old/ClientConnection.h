
#import <SenTestingKit/SenTestingKit.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>

@interface ClientConnection : SenTestCase {
	FLXPostgresServer* server;
	FLXPostgresConnection* client;
}

@property (retain) FLXPostgresServer* server;
@property (retain) FLXPostgresConnection* client;

@end
