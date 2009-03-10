
#import <SenTestingKit/SenTestingKit.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface ClientConnection : SenTestCase {
	FLXServer* server;
}

@property (retain) FLXServer* server;

@end
