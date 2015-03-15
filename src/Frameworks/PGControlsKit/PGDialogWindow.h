
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

/**
 *  This NSWindowController class provides a standard window which can be used
 *  in sheets, etc. The NIB file which it loads provides standard dialogs
 *  for various PostgreSQL tasks, such as defining connections, creating
 *  databases and roles, entering passwords and so forth.
 */

////////////////////////////////////////////////////////////////////////////////
// forward declarations

@protocol PGDialogDelegate;

////////////////////////////////////////////////////////////////////////////////

@interface PGDialogWindow : NSWindowController {
	PGConnection* _connection;
	NSMutableDictionary* _parameters;
}

////////////////////////////////////////////////////////////////////////////////
// static methods

/**
 *  Returns the default connection URL for a network-based PostgreSQL
 *  connection.
 *
 *  @return The URL which can be used as the default connection URL
 */
+(NSURL* )defaultNetworkURL;

/**
 *  Returns the default connection URL for a file-based PostgreSQL
 *  connection on the local machine.
 *
 *  @return The URL which can be used as the default connection URL
 */
+(NSURL* )defaultFileURL;

////////////////////////////////////////////////////////////////////////////////
// properties

@property (weak,nonatomic) IBOutlet PGDialogView* ibFileConnectionView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibNetworkConnectionView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibCreateRoleView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibCreateSchemaView;
@property (weak,nonatomic) IBOutlet PGDialogView* ibCreateDatabaseView;
@property (weak,nonatomic) id<PGDialogDelegate> delegate;


////////////////////////////////////////////////////////////////////////////////
// public properties

-(void)beginCustomSheetWithTitle:(NSString* )title description:(NSString* )description view:(PGDialogView* )view parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSModalResponse response)) callback;

@end

////////////////////////////////////////////////////////////////////////////////
// delegate

@protocol PGDialogDelegate <NSObject>
@optional
	-(void)controller:(PGDialogWindow* )controller dialogWillOpenWithParameters:(NSMutableDictionary* )parameters;
@end


