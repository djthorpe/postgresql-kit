
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
	NSURL* url = [NSURL URLWithLocalDatabase:nil username:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql:///",@"URLWithLocalDatabase failed");
}

-(void)test_001 {
	// normal database
	NSURL* url = [NSURL URLWithLocalDatabase:@"test" username:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test",@"URLWithLocalDatabase failed");
}

-(void)test_002 {
	// whitespace
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " username:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test",@"URLWithLocalDatabase failed");
}

-(void)test_003 {
	// one parameter
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " username:nil params:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"]];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test?key=value",@"URLWithLocalDatabase failed");
}

-(void)test_004 {
	// parameter with number
	NSDictionary* params = @{ @"key": @45 };
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " username:nil params:params];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test?key=45",@"URLWithLocalDatabase failed");
}

-(void)test_005 {
	// parameter with encoding
	NSDictionary* params = @{ @"key": @"a b" };
	NSURL* url = [NSURL URLWithLocalDatabase:@" test " username:nil params:params];
	STAssertEqualObjects([url absoluteString],@"pgsql:///test?key=a%20b",@"URLWithLocalDatabase failed");
}

-(void)test_006 {
	// localhost and username
	NSURL* url = [NSURL URLWithHost:nil ssl:NO username:@"username" database:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://username@localhost/",@"URLWithHost failed");
}

-(void)test_007 {
	// IP4 address
	NSURL* url = [NSURL URLWithHost:@"127.0.0.1" ssl:NO username:nil database:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://[127.0.0.1]/",@"URLWithHost failed");
}

-(void)test_008 {
	// IP6 address
	NSURL* url = [NSURL URLWithHost:@"::1" ssl:NO username:nil database:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://[::1]/",@"URLWithHost failed");
}

-(void)test_009 {
	// port
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" port:0 ssl:NO username:nil database:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://localhost.localdomain/",@"URLWithHost failed");
}

-(void)test_010 {
	// port
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" port:5934 ssl:NO username:nil database:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://localhost.localdomain:5934/",@"URLWithHost failed");
}

-(void)test_011 {
	// ssl
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" ssl:YES username:nil database:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsqls://localhost.localdomain/",@"URLWithHost failed");
}

-(void)test_012 {
	// all together
	NSDictionary* params = @{ @"key": @"=&test" };
	NSURL* url = [NSURL URLWithHost:@"localhost.localdomain" port:99 ssl:YES username:nil database:@"another_database" params:params];
	STAssertEqualObjects([url absoluteString],@"pgsqls://localhost.localdomain:99/another_database?key=%3D%26test",@"URLWithHost failed");
}

-(void)test_013 {
	// socket
	NSURL* url = [NSURL URLWithSocketPath:@"/tmp" port:0 database:@"database" username:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://%2Ftmp/database",@"URLWithSocketPath failed");
}

-(void)test_014 {
	// socket and port
	NSURL* url = [NSURL URLWithSocketPath:@"/tmp" port:999 database:@"database" username:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://%2Ftmp:999/database",@"URLWithSocketPath failed");
}

-(void)test_015 {
	// port
	NSURL* url = [NSURL URLWithSocketPath:nil port:999 database:@"database" username:nil params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://:999/database",@"URLWithSocketPath failed");
}

-(void)test_016 {
	// port and user
	NSURL* url = [NSURL URLWithSocketPath:nil port:999 database:@"database" username:@"user" params:nil];
	STAssertEqualObjects([url absoluteString],@"pgsql://user@:999/database",@"URLWithSocketPath failed");
}

@end

