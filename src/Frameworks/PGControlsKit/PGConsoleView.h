
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

@protocol PGConsoleViewDelegate <NSObject>
@required
	-(NSUInteger)numberOfRowsInConsoleView:(PGConsoleView* )view;
	-(NSString* )consoleView:(PGConsoleView* )view stringForRow:(NSUInteger)row;
@optional
	-(void)consoleView:(PGConsoleView* )view appendString:(NSString* )string;
@end

@interface PGConsoleView : NSViewController <NSTableViewDataSource, NSTableViewDelegate> {
	NSFont* _textFont;
	NSColor* _textColor;
	NSColor* _backgroundColor;
	BOOL _showGutter;
	BOOL _editable;
	NSMutableString* _editBuffer;
}

// properties
@property NSUInteger tag;
@property (assign) IBOutlet NSTableView* tableView;
@property (weak,nonatomic) id<PGConsoleViewDelegate> delegate;
@property NSFont* textFont;
@property NSColor* textColor;
@property NSColor* backgroundColor;
@property (readonly) CGFloat textHeight;
@property BOOL showGutter;
@property CGFloat defaultGutterWidth;
@property BOOL editable;
@property (readonly) NSMutableString* editBuffer;

// methods
-(void)reloadData;
-(void)scrollToBottom;

@end
