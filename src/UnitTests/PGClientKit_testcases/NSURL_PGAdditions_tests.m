
#import "NSURL_PGAdditions_tests.h"
#import <PGClientKit/PGClientKit.h>

@implementation NSURL_PGAdditions_tests

-(void)setUp {
    [super setUp];
	// TODO
}

-(void)tearDown {
	// TODO
    [super tearDown];
}

-(void)test_000 {
	NSURL* url = [NSURL URLWithLocalDatabase:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql:///",@"URLWithLocalDatabase failed");
}

-(void)test_001 {
	// normal database
	NSURL* url = [NSURL URLWithLocalDatabase:@"test" params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test",@"URLWithLocalDatabase failed");
}

-(void)test_002 {
	// whitespace
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test",@"URLWithLocalDatabase failed");
}

-(void)test_003 {
	// one parameter
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " params:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"]];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test?key=value",@"URLWithLocalDatabase failed");
}

-(void)test_004 {
	// parameter with number
	NSDictionary* params = @{ @"key": @45 };
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " params:params];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test?key=45",@"URLWithLocalDatabase failed");
}

-(void)test_005 {
	// parameter with encoding
	NSDictionary* params = @{ @"key": @"a b" };
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " params:params];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test?key=a%20b",@"URLWithLocalDatabase failed");
}

-(void)test_006 {
	// localhost
	NSURL* url = [NSURL URLWithHost:nil database:nil ssl:NO params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://localhost/",@"URLWithLocalDatabase failed");
}

-(void)test_007 {
	// IP4 address
	NSURL* url = [NSURL URLWithHost:@"127.0.0.1" database:nil ssl:NO params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://[127.0.0.1]/",@"URLWithLocalDatabase failed");
}

-(void)test_008 {
	// IP6 address
	NSURL* url = [NSURL URLWithHost:@"::1" database:nil ssl:NO params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://[::1]/",@"URLWithLocalDatabase failed");
}

-(void)test_009 {
	// port
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" port:0 database:nil ssl:NO params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://localhost.localdomain/",@"URLWithLocalDatabase failed");
}

-(void)test_010 {
	// port
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" port:5934 database:nil ssl:NO params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://localhost.localdomain:5934/",@"URLWithLocalDatabase failed");
}

-(void)test_011 {
	// ssl
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" database:nil ssl:YES params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsqls://localhost.localdomain/",@"URLWithLocalDatabase failed");
}

-(void)test_012 {
	// all together
	NSDictionary* params = @{ @"key": @"=&test" };
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" port:99 database:@"another_database" ssl:YES params:params];
	STAssertEqualObjects([url absoluteString],@"pgsqls://localhost.localdomain:99/another_database?key=%3D%26test",@"URLWithLocalDatabase failed");
}

@end

