
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

#import <Cocoa/Cocoa.h>
#import <PGClientKit/PGClientKit.h>

////////////////////////////////////////////////////////////////////////////////

typedef enum  {
	PGConnectionWindowStatusOK = 100,
	PGConnectionWindowStatusCancel,
	PGConnectionWindowStatusBadParameters,
	PGConnectionWindowStatusNeedsPassword,
	PGConnectionWindowStatusConnecting,
	PGConnectionWindowStatusConnected,
	PGConnectionWindowStatusRejected
} PGConnectionWindowStatus;

////////////////////////////////////////////////////////////////////////////////

@protocol PGConnectionWindowDelegate <NSObject>
@required
	-(void)connectionWindow:(PGConnectionWindowController* )windowController status:(PGConnectionWindowStatus)status;
@optional
	-(void)connectionWindow:(PGConnectionWindowController* )windowController error:(NSError* )error;
@end

////////////////////////////////////////////////////////////////////////////////

@interface PGConnectionWindowController : NSWindowController <PGConnectionDelegate> {
	PGConnection* _connection;
	NSMutableDictionary* _params;
	PGPasswordStore* _password;
	NSError* _lastError;
}

// properties
@property (weak,nonatomic) id<PGConnectionWindowDelegate> delegate;
@property BOOL useKeychain;
@property NSURL* url;
@property (readonly) PGPasswordStore* password;
@property (readonly) PGConnection* connection;
@property (readonly) NSError* lastError;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow;
-(void)beginPasswordSheetForParentWindow:(NSWindow* )parentWindow;
-(void)beginErrorSheetForParentWindow:(NSWindow* )parentWindow;
-(void)connect;
-(void)disconnect;

@end
