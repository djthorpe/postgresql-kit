
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

@interface PGDialogNetworkConnectionView : PGDialogView {
	NSTimer* _timer;
	PGConnection* _connection;
	NSLock* _waitLock;
}

// properties
@property (readonly) NSInteger port;
@property (readonly) NSString* sslmode;
@property (readonly) NSString* hostaddr;
@property (readonly) NSString* host;
@property (readonly) NSString* user;
@property (readonly) NSString* dbname;
@property (readonly) NSString* comment;
@property (readonly) NSURL* url;

@end
