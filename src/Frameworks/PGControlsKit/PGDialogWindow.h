
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
	PGDialogWindowFlagDisabled         = 0x0000,     // Disabled
	PGDialogWindowFlagEnabled          = 0x0001,     // Enabled
	PGDialogWindowFlagIndicatorMask    = 0x0070,     // Indicator mask
	PGDialogWindowFlagIndicatorGrey    = 0x0010,     // Grey indicator
	PGDialogWindowFlagIndicatorRed     = 0x0020,     // Red indicator
	PGDialogWindowFlagIndicatorOrange  = 0x0030,     // Orange indicator
	PGDialogWindowFlagIndicatorGreen   = 0x0040      // Green indicator
};

////////////////////////////////////////////////////////////////////////////////

@interface PGDialogWindow : NSWindowController <PGDialogDelegate> {
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
// public properties

@property (retain) NSString* windowTitle;
@property (retain) NSString* windowDescription;

////////////////////////////////////////////////////////////////////////////////
// public methods

/**
 *  This method initalizes the object by loading the NIB. You should call this
 *  method before accessing views.
 */
-(void)load;

/**
 *  This method displays a sheet attatched to a parent window, where the dialog
 *  parameters and PGDialogView objects are provided to style the sheet. When
 *  an action button is pressed (either OK or cancel) the sheet is dismissed
 *  and the callback called with the appropriate modal response.
 *
 *  @param parameters   The title for the sheet
 *  @param view         The PGDialogView view controller for the sheet contents
 *  @param parentWindow The NSWindow on which the sheet appears modally
 *  @param callback
 */
-(void)beginCustomSheetWithParameters:(NSDictionary* )parameters view:(PGDialogView* )view parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSModalResponse response)) callback;

/**
 *  This method displays a "Network Connection" or "File-based Connection" sheet
 *  above a parent window, in order to enter the details for a PostgreSQL
 *  connection. If the URL is nil, it assumes a network-based connection, or
 *  a URL can be passed from the defaultNetworkURL or defaultFileURL static
 *  methods. When done, the callback provides the entered URL, or nil if the
 *  cancel button was pressed.
 *
 *  @param url          The URL which is used to "fill all the details in" for the
 *                      sheet
 *  @param comment      The comment associated with the URL, or nil
 *  @param parentWindow The NSWindow on which the sheet appears modally
 *  @param callback     The callback which is called once the sheet is dismissed
 */
-(void)beginConnectionSheetWithURL:(NSURL* )url comment:(NSString* )comment parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSURL* url,NSString* comment)) callback;


/**
 *  This method provides a sheet to enter a password, and indicate whether the
 *  password should be saved in the users' keychain. When done, the callback 
 *  provides the password and the user preference on saving to keychain. The
 *  password returned is nil if the cancel button was pressed.
 *
 */
-(void)beginPasswordSheetSaveInKeychain:(BOOL)saveinKeychain parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(NSString* password,BOOL saveInKeychain)) callback;

/**
 *  This method displays a "Create Role" or "Alter Role" sheet above a parent 
 *  window, in order to allow the user to enter the details necessary for 
 *  creating or updating a role. When done, the callback provides a PGTransaction
 *  object which can be used for creating or modfying the role, or nil if the 
 *  sheet was cancelled.
 *
 *  @param parameters   The initial parameters used for display.
 *  @param connection   The connection used to fetch the current roles
 *  @param parentWindow The NSWindow on which the sheet appears modally
 *  @param callback     The callback which is called once the sheet is dismissed
 */
-(void)beginRoleSheetWithParameters:(NSDictionary* )parameters connection:(PGConnection* )connection parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(PGTransaction* transaction)) callback;

/**
 *  This method displays a "Create Schema" or "Alter Schema" sheet above a 
 *  parent window, in order to allow the user to enter the details necessary
 *  for creating or altering a schema. When done, the callback provides a 
 *  PGTransaction object which can be used for creating or altering the schema, or
 *  nil if the sheet was cancelled.
 *
 *  @param parameters   The initial parameters used for display, or nil otherwise
 *  @param connection   The connection used to fetch the current roles
 *  @param parentWindow The NSWindow on which the sheet appears modally
 *  @param callback     The callback which is called once the sheet is dismissed
 */
-(void)beginSchemaSheetWithParameters:(NSDictionary* )parameters connection:(PGConnection* )connection parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(PGTransaction* query)) callback;

/**
 *  This method displays a "Create Database" or "Alter Schema" sheet above a 
 *  parent window, in order to allow the user to enter the details necessary 
 *  for creating or altering a database. When done, the callback provides a 
 *  PGTransaction object which can be used for creating or altering the database
 *  parameters, o r nil if the sheet was cancelled.
 *
 *  @param parameters   The initial parameters used for display.
 *  @param connection   The connection used to fetch the current roles
 *  @param parentWindow The NSWindow on which the sheet appears modally
 *  @param callback     The callback which is called once the sheet is dismissed
 */
-(void)beginDatabaseSheetWithParameters:(NSDictionary* )parameters connection:(PGConnection* )connection parentWindow:(NSWindow* )parentWindow whenDone:(void(^)(PGTransaction* query)) callback;


@end

