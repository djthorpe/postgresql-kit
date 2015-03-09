
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
#import <PGClientKit/PGClientKit.h>
#import "PGFoundationServer.h"

 /**
  *  This class is the harness for the unit tests. It creates a server and a
  *  client, and can connect them together. The unit tests can then use the
  *  server and client objects within the tests. 
  *
  *  The -(BOOL)setUp routine will create
  *  a new server with a fresh database if not already done, and create a client
  *  object.
  *
  *  The -(BOOL)tearDown method will only do something if the lastTest flag is 
  *  set...in that case, it will disconnect the client from the server, and
  *  delete the data.
  *
  *  The -(NSURL* )url property provides the URL for the client to connect to
  *  the server.
  *
  *  The -(BOOL)connectClientToServer method will connect the client object to
  *  the server object, assuming the server is running.
  *
  */

@interface PGUnitTester : NSObject <PGConnectionDelegate> {
	PGFoundationServer* _server;
	PGConnection* _client;
	NSUInteger _port;
	BOOL _lastTest;
}

@property (readonly) PGFoundationServer* server;
@property (readonly) PGConnection* client;
@property (readonly) NSUInteger port;
@property BOOL lastTest;
@property (readonly) NSURL* url;

-(BOOL)setUp;
-(BOOL)tearDown;

@end
