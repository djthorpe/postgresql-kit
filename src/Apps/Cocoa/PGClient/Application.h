
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
#import <PGControlsKit/PGControlsKit.h>
#import "ConsoleBuffer.h"

@interface Application : NSObject <NSApplicationDelegate,PGSourceViewDelegate,PGConnectionPoolDelegate,PGTabViewDelegate,PGConsoleViewDelegate> {
	PGConnectionPool* _connections;
	PGSplitViewController* _splitView;
	PGSourceViewController* _sourceView;
	PGTabViewController* _tabView;
	PGHelpWindowController* _helpWindow;
	PGConnectionWindowController* _connectionWindow;
	ConsoleBuffer* _buffers;
}

// properties
@property (readonly) PGConnectionPool* connections;
@property (readonly) PGSplitViewController* splitView;
@property (readonly) PGTabViewController* tabView;
@property (readonly) PGSourceViewController* sourceView;
@property (readonly) PGHelpWindowController* helpWindow;
@property (readonly) PGConnectionWindowController* connectionWindow;

@end

