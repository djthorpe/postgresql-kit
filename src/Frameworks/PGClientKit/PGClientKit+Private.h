
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

#include <libpq-fe.h>
#include <pg_config.h>

// use DEBUG2 for additional output
#ifdef DEBUG
//#define DEBUG2
#endif

 /**
  *  This file includes declarations which are private to the framework
  */

#import "PGClientParams.h"
#import "PGConverters.h"
#import "NSString+PrivateAdditions.h"

@interface PGConnection (Private)
-(void)_updateStatus;
-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code reason:(NSString* )format,...;
-(NSError* )raiseError:(NSError** )error code:(PGClientErrorDomainCode)code;
-(void)_socketConnect:(PGConnectionState)state;
-(void)_socketDisconnect;
-(void)_socketCallback:(CFSocketCallBackType)callBackType;
-(NSDictionary* )_connectionParametersForURL:(NSURL* )theURL;
-(BOOL)_cancelCreate;
-(void)_cancelDestroy;
@end

@interface PGResult (Private)
-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format;
@end

@interface PGQueryPredicate (Private)
+(PGQueryPredicate* )predicateOrExpression:(id)expression;
@end

@interface PGTransaction (Private)
-(NSString* )quoteBeginTransactionForConnection:(PGConnection* )connection;
-(NSString* )quoteRollbackTransactionForConnection:(PGConnection* )connection;
-(NSString* )quoteCommitTransactionForConnection:(PGConnection* )connection;
@end

typedef struct {
	const char** keywords;
	const char** values;
} PGKVPairs;

PGKVPairs* makeKVPairs(NSDictionary* dict);
void freeKVPairs(PGKVPairs* pairs);

// profiling macros
#ifdef DEBUG2
#include <mach/mach_time.h>
#define TIME_TICK(name) NSLog(@"TICK: %@",(name)); \
                        uint64_t tick_time = mach_absolute_time(); \
						double time_elapsed_ns = 0; \
						mach_timebase_info_data_t tick_info; \
						mach_timebase_info(&tick_info);
#define TIME_TOCK(name) time_elapsed_ns = ((double)(mach_absolute_time() - tick_time) * (double)tick_info.numer / (double)tick_info.denom); \
                        tick_time = mach_absolute_time(); \
                        NSLog(@"TOCK: %@: %.1lfms",(name),time_elapsed_ns/1000.0);
#else
#define TIME_TICK(name)
#define TIME_TOCK(name)
#endif

