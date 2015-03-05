
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
#import "GBCli.h"

@interface PGFoundationApp : NSObject {
	BOOL _stop;
	int _returnValue;
	GBSettings* _settings;
}

// constructor
+(id)sharedApp;

// properties
@property (readonly) BOOL stopping;
@property (readonly) GBSettings* settings;

// methods

// run is called to start the application and will block. will return 0 on
// successful completion, or error code otherwise
-(int)run;

// setup is called to do one-time initial set-up, you can override this method
-(BOOL)setup;

// call stop when you wish to stop the application
-(void)stop;

// you should call stopped when the application is finally stopped
-(void)stoppedWithReturnValue:(int)returnValue;

// parsing command-line options
-(BOOL)parseOptionsWithArguments:(const char** )argv count:(int)argc error:(NSError** )error;
-(void)registerCommandLineOptionsWithParser:(GBCommandLineParser* )parser;

@end
