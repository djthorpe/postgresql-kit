
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

// Forward class delarations
@class PGSplitViewController;

@class PGConnectionWindowController;

@class PGSourceViewController;
@class PGSourceViewNode;
  @class PGSourceViewHeading;
  @class PGSourceViewConnection;

@class PGTabViewController;

@class PGHelpWindowController;

@class PGConsoleViewController;
@class PGConsoleViewBuffer;

// PGDialog forward declarations
@class PGDialogWindow;
@class PGDialogView;
  @class PGDialogDatabaseView;
  @class PGDialogRoleView;
  @class PGDialogSchemaView;
  @class PGDialogPasswordView;
  @class PGDialogNetworkConnectionView;
    @class PGDialogFileConnectionView;

// PGDialog
#import "PGDialogWindow.h"
#import "PGDialogView.h"
#import "PGDialogDatabaseView.h"
#import "PGDialogSchemaView.h"
#import "PGDialogRoleView.h"
#import "PGDialogPasswordView.h"
#import "PGDialogNetworkConnectionView.h"
#import "PGDialogFileConnectionView.h"

// Windows
#import "PGConnectionWindowController.h"
#import "PGHelpWindowController.h"

// Views
#import "PGSplitViewController.h"
#import "PGSourceViewController.h"
#import "PGTabViewController.h"
#import "PGConsoleViewController.h"

// Nodes for Source View
#import "PGSourceViewNode.h"
#import "PGSourceViewHeading.h"
#import "PGSourceViewConnection.h"

// Buffer model for console view
#import "PGConsoleViewBuffer.h"


