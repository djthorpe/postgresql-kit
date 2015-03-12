
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <PGClientKit/PGClientKit.h>
#import "PGUnitTester.h"

////////////////////////////////////////////////////////////////////////////////

@interface PGQuery_tests : XCTestCase {
	PGUnitTester* tester;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGQuery_tests

////////////////////////////////////////////////////////////////////////////////

-(instancetype)init {
	self = [super init];
	if(self) {
		tester = [PGUnitTester new];
		NSParameterAssert(tester);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////

-(void)setUp {
    [super setUp];
	if(tester==nil) {
		tester = [PGUnitTester new];
	}
	XCTAssertTrue([tester setUp]);
	
	// perform connection
	XCTAssert([tester url]);
	XCTestExpectation* expectation = [self expectationWithDescription:@"Connect"];
	[[tester client] connectWithURL:[tester url] whenDone:^(BOOL usedPassword, NSError *error) {
		XCTAssert(usedPassword==NO);
		XCTAssert(error==nil);
		XCTAssertEqual([[tester client] status],PGConnectionStatusConnected);
		XCTAssert([[tester client] serverProcessID] != 0);
		XCTAssert([[tester client] user]);
		XCTAssert([[tester client] database]);
		[expectation fulfill];
	}];

	// wait for callback to complete
	[self waitForExpectationsWithTimeout:1.0 handler:^(NSError *error) {
		XCTAssertNil(error,@"Timeout Error: %@", error);
	}];
	
	
}

-(void)tearDown {
	// disconnect client
	[[tester client] disconnect];
	// potentially disconnect server
    XCTAssertTrue([tester tearDown]);
	[super tearDown];
}

////////////////////////////////////////////////////////////////////////////////

-(void)test_001_createquery {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuery* query = [PGQuery new];
	XCTAssertNil(query,@"new method does not return nil");
}

-(void)test_002_basicquery {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	NSString* statement = @"SELECT 1";
	PGQuery* query = [PGQuery queryWithString:statement];
	XCTAssertEqualObjects(statement,[query quoteForConnection:client error:nil],@"statements are not equal");
}

-(void)test_003_null {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	NSString* statement = @"NULL";
	PGQueryPredicate* query = [PGQueryPredicate nullPredicate];
	XCTAssertEqualObjects(statement,[query quoteForConnection:client error:nil],@"statements are not equal");
}

-(void)test_004_string {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQueryPredicate* input = [PGQueryPredicate string:@"SELECT 1"];
	NSString* output = @"'SELECT 1'";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_005_basicselect {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	NSString* output = @"SELECT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_006_selectdistinct {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	NSString* output = @"SELECT DISTINCT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_007_selectlimit {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setLimit:1];
	NSString* output = @"SELECT DISTINCT * FROM table LIMIT 1";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_008_selectnolimit {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setLimit:PGQuerySelectNoLimit];
	NSString* output = @"SELECT DISTINCT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_009_selectzerolimit {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setLimit:0];
	NSString* output = @"SELECT DISTINCT * FROM table LIMIT 0";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_010_selectoffset {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setOffset:0];
	NSString* output = @"SELECT DISTINCT * FROM table";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_011_selectoffset {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setOffset:1];
	NSString* output = @"SELECT DISTINCT * FROM table OFFSET 1";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_012_selectoffsetlimit {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:PGQueryOptionDistinct];
	[input setOffset:10 limit:10];
	NSString* output = @"SELECT DISTINCT * FROM table OFFSET 10 LIMIT 10";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_013_selectand {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input andWhere:@"NULL"];
	NSString* output = @"SELECT * FROM table WHERE NULL";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_014_selectand {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input andWhere:@"NULL1"];
	[input andWhere:@"NULL2"];
	NSString* output = @"SELECT * FROM table WHERE NULL1 AND NULL2";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_015_selector {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input andWhere:@"NULL1"];
	[input orWhere:@"NULL2"];
	NSString* output = @"SELECT * FROM table WHERE (NULL1 OR NULL2)";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_016_selector {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	PGQuerySelect* input = [PGQuerySelect select:@"table" options:0];
	[input orWhere:@"NULL1"];
	[input orWhere:@"NULL2"];
	[input orWhere:@"NULL3"];
	NSString* output = @"SELECT * FROM table WHERE (NULL1 OR NULL2 OR NULL3)";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_017_createdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase create:@"database" options:0];
	NSString* output = @"CREATE DATABASE database";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_018_createdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase create:@"database" options:0];
	[input setOwner:@"owner"];
	NSString* output = @"CREATE DATABASE database WITH OWNER owner";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
	
	[input setOwner:nil];
	output = @"CREATE DATABASE database";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_019_createdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase create:@"database" options:0];
	[input setTemplate:@"template"];
	NSString* output = @"CREATE DATABASE database WITH TEMPLATE template";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);

	[input setTemplate:nil];
	output = @"CREATE DATABASE database";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_020_createdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase create:@"database" options:0];
	[input setEncoding:@"encoding"];
	NSString* output = @"CREATE DATABASE database WITH ENCODING 'encoding'";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);

	[input setEncoding:@""];
	output = @"CREATE DATABASE database";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
	
	[input setOptionFlags:PGQueryOptionSetEncoding];
	output = @"CREATE DATABASE database WITH ENCODING DEFAULT";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
	
}

-(void)test_021_createdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase create:@"database" options:0];
	[input setTablespace:@"tablespace"];
	NSString* output = @"CREATE DATABASE database WITH TABLESPACE tablespace";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);

	[input setTablespace:@""];
	output = @"CREATE DATABASE database";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
	
	[input setOptionFlags:PGQueryOptionSetTablespace];
	output = @"CREATE DATABASE database WITH TABLESPACE DEFAULT";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);

}

-(void)test_022_createdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase create:@"database" options:0];
	[input setConnectionLimit:0];
	NSString* output = @"CREATE DATABASE database WITH CONNECTION LIMIT 0";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);

	[input setConnectionLimit:1];
	output = @"CREATE DATABASE database WITH CONNECTION LIMIT 1";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);

	[input setConnectionLimit:-1];
	output = @"CREATE DATABASE database";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_023_dropdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase drop:@"database" options:0];
	NSString* output = @"DROP DATABASE database";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_024_dropdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase drop:@"database" options:PGQueryOptionIgnoreIfNotExists];
	NSString* output = @"DROP DATABASE IF EXISTS database";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_025_alterdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase alter:@"database" name:@"newname"];
	NSString* output = @"ALTER DATABASE database RENAME TO newname";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_026_alterdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase alter:@"database" connectionLimit:10];
	NSString* output = @"ALTER DATABASE database WITH CONNECTION LIMIT 10";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
	
	input = [PGQueryDatabase alter:@"database" connectionLimit:-1];
	output = @"ALTER DATABASE database WITH CONNECTION LIMIT -1";
	comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_027_alterdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase alter:@"database" owner:@"newowner"];
	NSString* output = @"ALTER DATABASE database OWNER TO newowner";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_028_alterdatabase {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryDatabase* input = [PGQueryDatabase alter:@"database" tablespace:@"tablespace"];
	NSString* output = @"ALTER DATABASE database SET TABLESPACE tablespace";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_029_createschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema create:@"schema" options:0];
	NSString* output = @"CREATE SCHEMA schema";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_030_createschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema create:@"schema" options:0];
	[input setOwner:@"owner"];
	NSString* output = @"CREATE SCHEMA schema AUTHORIZATION owner";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_031_createschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema create:@"schema" options:PGQueryOptionIgnoreIfExists];
	NSString* output = @"CREATE SCHEMA IF NOT EXISTS schema";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_032_dropschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema drop:@"schema" options:0];
	NSString* output = @"DROP SCHEMA schema RESTRICT";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_033_dropschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema drop:@"schema" options:PGQueryOptionIgnoreIfNotExists];
	NSString* output = @"DROP SCHEMA IF EXISTS schema RESTRICT";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_034_dropschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema drop:@"schema" options:(PGQueryOptionIgnoreIfNotExists | PGQueryOptionDropObjects)];
	NSString* output = @"DROP SCHEMA IF EXISTS schema CASCADE";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_035_alterschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema alter:@"schema" name:@"newname"];
	NSString* output = @"ALTER SCHEMA schema RENAME TO newname";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_036_alterschema {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQuerySchema* input = [PGQuerySchema alter:@"schema" owner:@"owner"];
	NSString* output = @"ALTER SCHEMA schema OWNER TO owner";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_037_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:0];
	NSString* output = @"CREATE ROLE role";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_038_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:PGQueryOptionPrivSuperuserSet];
	NSString* output = @"CREATE ROLE role WITH SUPERUSER";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_039_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:PGQueryOptionPrivSuperuserClear];
	NSString* output = @"CREATE ROLE role WITH NOSUPERUSER";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_040_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:(PGQueryOptionPrivSuperuserClear | PGQueryOptionPrivSuperuserSet)];
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNil(comparison);
}

-(void)test_041_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:PGQueryOptionPrivCreateDatabaseSet];
	NSString* output = @"CREATE ROLE role WITH CREATEDB";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_042_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:PGQueryOptionPrivCreateDatabaseClear];
	NSString* output = @"CREATE ROLE role WITH NOCREATEDB";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_043_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:(PGQueryOptionPrivCreateDatabaseClear | PGQueryOptionPrivSuperuserSet)];
	NSString* output = @"CREATE ROLE role WITH SUPERUSER NOCREATEDB";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}

-(void)test_044_createrole {
	PGConnection* client = [tester client];
	XCTAssertNotNil(client,@"client is nil");
	
	PGQueryRole* input = [PGQueryRole create:@"role" options:(PGQueryOptionPrivCreateDatabaseSet | PGQueryOptionPrivSuperuserClear)];
	NSString* output = @"CREATE ROLE role WITH NOSUPERUSER CREATEDB";
	NSString* comparison = [input quoteForConnection:client error:nil];
	XCTAssertNotNil(comparison);
	XCTAssertEqualObjects(output,comparison,@"statements are not equal: %@",comparison);
}


-(void)test_999 {
	[tester setLastTest:YES];
}

@end
