
#import <SenTestingKit/SenTestingKit.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>

@interface ClientConnection : SenTestCase {
	FLXServer* server;
	FLXPostgresConnection* client;
}

@property (retain) FLXServer* server;
@property (retain) FLXPostgresConnection* client;

@end
