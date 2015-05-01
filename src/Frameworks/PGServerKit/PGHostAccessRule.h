
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

typedef enum {
	PGHostAccessConnTypeUnknown      = 0,
	PGHostAccessConnTypeLocal        = 1,
	PGHostAccessConnTypeHost         = 2,
	PGHostAccessConnTypeHostSSL      = 3,
	PGHostAccessConnTypeHostNoSSL    = 4
} PGHostAccessConnType;

typedef enum {
	PGHostAccessAuthTypeUnknown            = 0,
	PGHostAccessAuthTypeTrust              = 1,
	PGHostAccessAuthTypeReject             = 2,
	PGHostAccessAuthTypeMD5                = 3,
	PGHostAccessAuthTypePassword           = 4,
	PGHostAccessAuthTypeGSS                = 5,
	PGHostAccessAuthTypeSSPI               = 6,
	PGHostAccessAuthTypeKRB5               = 7,
	PGHostAccessAuthTypeIdent              = 8,
	PGHostAccessAuthTypePeer               = 9,
	PGHostAccessAuthTypeLDAP               = 10,
	PGHostAccessAuthTypeRadius             = 11,
	PGHostAccessAuthTypeCert               = 12,
	PGHostAccessAuthTypePAM                = 13
} PGHostAccessAuthType;

@interface PGHostAccessRule : NSObject {
	PGHostAccessConnType _conntype;
	NSArray* _databases;
	NSArray* _users;
	NSString* _address;
	PGHostAccessAuthType _authtype;
	NSDictionary* _authoptions;
	NSString* _comment;
}

// constructor
-(instancetype)initWithString:(NSString* )string;

// properties
@property (assign) PGHostAccessConnType conntype;
@property (retain) NSArray* databases;
@property (retain) NSArray* users;
@property (retain) NSString* address;
@property (assign) PGHostAccessAuthType authtype;
@property (retain) NSDictionary* authoptions;
@property (retain) NSString* comment;

// methods
-(NSData* )dataWithEncoding:(NSStringEncoding)encoding;

@end
