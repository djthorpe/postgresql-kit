
#import <SenTestingKit/SenTestingKit.h>
#import <PostgresClientKit/PostgresClientKit.h>

@interface TypeTests : SenTestCase {
	FLXPostgresConnection* database;
}

@property (retain) FLXPostgresConnection* database;

@end
