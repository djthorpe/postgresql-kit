
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
 *  This PGDialogDelegate class provides a standard window which can be used
 *  in sheets, etc. The NIB file which it loads provides standard dialogs
 *  for various PostgreSQL tasks, such as defining connections, creating
 *  databases and roles, entering passwords and so forth. In order to use this
 *  class, a PGDialogView instance is required, which represents an NSView
 */

////////////////////////////////////////////////////////////////////////////////
// delegate

@protocol PGDialogDelegate <NSObject>
@optional
	-(void)view:(PGDialogView* )view setFlags:(int)flags description:(NSString* )description;
@end


////////////////////////////////////////////////////////////////////////////////
// flags

enum {
	PGDialogWindowFlagEnabled          = 0x01,     // OK action is enabled
	PGDialogWindowFlagIndicatorGrey    = 0x02,     // Grey indicator
	PGDialogWindowFlagIndicatorRed     = 0x04,     // Red indicator
	PGDialogWindowFlagIndicatorOrange  = 0x08,     // Orange indicator
	PGDialogWindowFlagIndicatorGreen   = 0x10      // Green indicator
};

////////////////////////////////////////////////////////////////////////////////

@interface PGDialogWindow : NSWindowController <PGDialogDelegate> {
	PGConnection* _connection;
	NSMutableDictionary* _parameters;
	NSSize _offset;
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

/**
 *  This method initalizes the object by loading the NIB. You should call this
 *  method before accessing views.
 */
-(void)load;

/**
 *  This method displays a sheet attatched to a parent window, where the title,
 *  description and PGDialogView objects are provided to style the sheet. When
 *  an action button is pressed (either OK or cancel) the sheet is dismissed
 *  and the callback called.
 *
 *  @param title        The title for the sheet
 *  @param description  An optional description for the sheet
 *  @param view         The PGDialogView view controller for the sheet contents
 *  @param parentWindow The NSWindow on which the sheet appears modally
 *  @param callback
 */
-(void)beginCustomSheetWithTitle:(NSString* )title description:(NSString* )description view:(PGDialogView* )view parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSModalResponse response)) callback;

/**
 *  This method displays a "Network Connection" sheet above a window, in order to
 *  enter the details for a PostgreSQL network connection.
 *
 *  @param url          The URL which is used to "fill all the details in" for the
 *                      sheet
 *  @param parentWindow The NSWindow on which the sheet appears modally
 *  @param callback     The callback which is called once the sheet is dismissed
 */
-(void)beginNetworkConnectionSheetWithURL:(NSURL* )url parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url,NSModalResponse response)) callback;

@end

