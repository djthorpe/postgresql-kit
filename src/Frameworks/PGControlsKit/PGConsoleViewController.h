
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


////////////////////////////////////////////////////////////////////////////////

@protocol PGConsoleViewDataSource <NSObject>
@required
	-(NSUInteger)numberOfRowsForConsoleView:(PGConsoleViewController* )view;
	-(NSString* )consoleView:(PGConsoleViewController* )consoleView stringForRow:(NSUInteger)row;
@optional
	-(NSColor* )consoleView:(PGConsoleViewController* )consoleView textColorForRow:(NSUInteger)row;
@end

@protocol PGConsoleViewDelegate <NSObject>
@optional
	-(void)consoleView:(PGConsoleViewController* )consoleView append:(NSString* )string;
@end

////////////////////////////////////////////////////////////////////////////////

@interface PGConsoleViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate> {
	NSFont* _textFont;
	NSColor* _textColor;
	NSColor* _backgroundColor;
	NSMutableString* _editBuffer;
}

// properties
@property (weak) id<PGConsoleViewDataSource> dataSource;
@property (weak) id<PGConsoleViewDelegate> delegate;
@property NSInteger tag;
@property BOOL editable;
@property NSString* prompt;
@property (readonly) NSUInteger textWidth;

// methods
-(void)reloadData;
-(void)reloadEditBuffer;
-(void)scrollToBottom;

@end
