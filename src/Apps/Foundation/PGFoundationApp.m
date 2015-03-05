
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

#import "PGFoundationApp.h"
#import "GBCli.h"

static PGFoundationApp* app = nil;

////////////////////////////////////////////////////////////////////////////////

void handleSIGTERM(int signal) {
	printf("Caught signal: %d\n",signal);
	[app stop];
}

void setHandleSignal() {
	// handle TERM and INT signals 
//	signal(SIGTERM,handleSIGTERM);
	signal(SIGINT,handleSIGTERM);	  
//	signal(SIGKILL,handleSIGTERM);
//	signal(SIGQUIT,handleSIGTERM);
}

////////////////////////////////////////////////////////////////////////////////

@implementation PGFoundationApp

+(id)sharedApp {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,^{
		app = [[self alloc] init];
	});
	return app;
}

-(id)init {
	self = [super init];
	if(self) {
		_stop = NO;
		_returnValue = 0;
		_settings = [GBSettings settingsWithName:@"settings" parent:nil];
		setHandleSignal();
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize stopping = _stop;
@synthesize settings = _settings;

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)timerFired:(id)theTimer {
	// call the init method
	BOOL returnValue = [self setup];
	if(returnValue==NO) {
		_stop = YES;
		[self stoppedWithReturnValue:-1];
	}
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)registerCommandLineOptionsWithParser:(GBCommandLineParser* )parser {
	[parser registerOption:@"help" shortcut:'?' requirement:GBValueNone];
}

-(BOOL)parseOptionsWithArguments:(const char** )argv count:(int)argc error:(NSError** )error {
	NSParameterAssert(argv);
	NSParameterAssert(error);
	GBCommandLineParser* parser = [[GBCommandLineParser alloc] init];
	__block BOOL returnValue = YES;
	
	[self registerCommandLineOptionsWithParser:(GBCommandLineParser* )parser];
	
	[parser parseOptionsWithArguments:(char** )argv count:argc block:^(GBParseFlags flags, NSString* option, id value, BOOL* stop) {
        switch (flags) {
            case GBParseFlagUnknownOption:
				// TODO: put into NSError* message
                printf("Unknown command line option %s, try --help\n", [option UTF8String]);
				(*stop) = YES;
				returnValue = NO;
                break;
            case GBParseFlagMissingValue:
				// TODO: put into NSError* message
                printf("Missing value for command line option %s, try --help\n", [option UTF8String]);
				(*stop) = YES;
				returnValue = NO;
                break;
            case GBParseFlagOption:
				[[self settings] setObject:value forKey:option];
                break;
            case GBParseFlagArgument:
				[[self settings] addArgument:value];
                break;
        }
    }];
	return returnValue;
}

-(void)stop {
	_stop = YES;
}

-(void)stoppedWithReturnValue:(int)returnValue {
	NSParameterAssert(_stop==YES);
	_returnValue = returnValue;
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

-(int)run {
	// set return value to be positive number
	_stop = NO;
	_returnValue = 0;
	
	// schedule
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
	
	// start the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
	} while(isRunning==YES && _stop==NO);

#ifdef DEBUG
	printf("returnValue=%d\n",_returnValue);
#endif

	// return the code
	return _returnValue;
}

-(BOOL)setup {
	// do nothing - needs override
	return YES;
}

@end
