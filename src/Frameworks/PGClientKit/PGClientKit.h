
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

////////////////////////////////////////////////////////////////////////////////

// typedefs
typedef enum {
	PGConnectionStatusDisconnected = 0, // not connected
	PGConnectionStatusConnected = 1,    // connected and idle
	PGConnectionStatusRejected = 2,     // not connected, rejected connection
	PGConnectionStatusConnecting = 3,   // busy connecting
	PGConnectionStatusBusy = 4          // connected and busy
} PGConnectionStatus;

typedef enum {
	PGClientTupleFormatText = 0,
	PGClientTupleFormatBinary = 1
} PGClientTupleFormat;

typedef enum {
	PGClientErrorNone = 0,                // no error occured
	PGClientErrorState = 100,             // state is wrong for this call
	PGClientErrorParameters = 101,        // invalid parameters
	PGClientErrorNeedsPassword = 102,     // password required
	PGClientErrorInvalidPassword = 103,   // password failure
	PGClientErrorRejected = 104,          // rejected from operation
	PGClientErrorExecute = 105,           // execution error
	PGClientErrorQuery = 106,             // invalid query
	PGClientErrorUnknown = 107            // unknown error
} PGClientErrorDomainCode;

////////////////////////////////////////////////////////////////////////////////

// forward class declarations
@class PGConnection;
@class PGConnectionPool;
@class PGPasswordStore;

@class PGResult;

@class PGQuery;
  @class PGQueryCreate;
  @class PGSelect;


// header includes
#import "PGConnection.h"
#import "PGConnectionPool.h"
#import "PGResult.h"

// queries
#import "PGQuery.h"
#import "PGQueryCreate.h"
#import "PGSelect.h"

// helpers
#import "NSURL+PGAdditions.h"
#import "NSString+PGNetworkValidationAdditions.h"
#import "PGPasswordStore.h"

#if TARGET_OS_IPHONE
// Do not import additional header files
#else
// Import Mac OS X specific header files
#import "PGResult+TextTable.h"
#endif
