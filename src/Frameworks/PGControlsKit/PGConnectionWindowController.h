
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

@interface PGConnectionWindowController : NSWindowController {
	PGConnection* _connection;
	NSMutableDictionary* _params;
}

// static methods
+(NSURL* )defaultNetworkURL;
+(NSURL* )defaultSocketURL;

// properties
@property (weak,nonatomic) IBOutlet NSView* ibCreateRoleView;
@property (weak,nonatomic) IBOutlet NSView* ibCreateSchemaView;
@property (weak,nonatomic) IBOutlet NSView* ibCreateDatabaseView;

// methods to show dialogs
-(void)beginConnectionSheetWithURL:(NSURL* )url parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url)) callback;
-(void)beginPasswordSheetWithParentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSString* password,BOOL useKeychain)) callback;
-(void)beginErrorSheetWithError:(NSError* )error parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSModalResponse response)) callback;
-(void)beginCustomSheetWithTitle:(NSString* )title description:(NSString* )description view:(NSView* )view parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSModalResponse response)) callback;

@end
