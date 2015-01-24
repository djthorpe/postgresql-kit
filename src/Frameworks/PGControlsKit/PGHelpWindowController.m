
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

#import <PGControlsKit/PGControlsKit.h>
#import "MMMarkdown.h"

@interface PGHelpWindowController ()

// private properties
@property (weak,nonatomic) IBOutlet NSTableView* ibTableView;
@property (assign,nonatomic) IBOutlet NSTextView* ibTextView;
@property (readonly) NSAttributedString* text;
@property (readonly) NSMutableArray* files;

@end

///////////////////////////////////////////////////////////////////////////////

NSString* PGHelpWindowResourceType = @"md";

///////////////////////////////////////////////////////////////////////////////

@implementation PGHelpWindowController

///////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		_text = [NSAttributedString new];
		_files = [NSMutableArray new];
		NSParameterAssert(_text && _files);
	}
	return self;
}

-(NSString* )windowNibName {
	return @"PGHelpWindow";
}

-(void)windowDidLoad {
    [super windowDidLoad];
	// knit up delegates, etc
	NSParameterAssert([self ibTableView] && [self ibTextView]);
	[[self ibTableView] setDelegate:self];
	[[self ibTableView] setDataSource:self];
}

///////////////////////////////////////////////////////////////////////////////
// properties

@synthesize ibTableView;
@synthesize ibTextView;
@synthesize text = _text;

-(NSFont* )font {
	return [NSFont fontWithName:@"Helvetica" size:24];
}

-(NSDictionary* )documentAttributes {
	return @{
		NSFontAttributeName: [self font],
	};
}

-(NSString* )headerString {
	return @"<html><head><style>body { font-family: Arial; font-size: 14px; } code { background-color: #eee; } </style></head><body>";
}

-(NSString* )footerString {
	return @"</body></html>";
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSData* )htmlDataFromFile:(NSString* )fileName stringEncoding:(NSStringEncoding)stringEncoding error:(NSError** )error {
	NSString* string = [NSString stringWithContentsOfFile:fileName encoding:stringEncoding error:error];
	if(string==nil) {
		return nil;
	}
	NSMutableString* htmlString = [NSMutableString stringWithString:[MMMarkdown HTMLStringWithMarkdown:string extensions:MMMarkdownExtensionsGitHubFlavored error:error]];
	if(htmlString==nil) {
		return nil;
	}
	// append header and footer onto the string
	[htmlString insertString:[self headerString] atIndex:0];
	[htmlString appendString:[self footerString]];	
	return [htmlString dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSData* )htmlDataFromFile:(NSString* )fileName error:(NSError** )error {
	return [self htmlDataFromFile:fileName stringEncoding:NSUTF8StringEncoding error:error];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)setVisible:(BOOL)isVisible {
	if(isVisible) {
		[[self window] orderFront:self];
		if([[self window] isKeyWindow]==NO) {
			[[self window] makeKeyWindow];
			NSLog(@"TODO: load the current selection");
		}
	} else {
		[[self window] orderOut:self];
	}
}

-(BOOL)displayHelpFromMarkdownFile:(NSString* )fileName error:(NSError** )error {
	NSLog(@"loading = %@",fileName);
	NSData* data = [self htmlDataFromFile:fileName error:error];
	if(data==nil) {
		return NO;
	}
	[self willChangeValueForKey:@"text"];
	NSDictionary* attributes = [self documentAttributes];
	_text = [[NSAttributedString alloc] initWithHTML:data documentAttributes:&attributes];
	[self didChangeValueForKey:@"text"];
	[self setVisible:YES];
	return YES;
}

-(void)addMarkdownFile:(NSString* )fileName {
	[[self files] addObject:fileName];
}

-(BOOL)displayHelpFromMarkdownResource:(NSString* )resourceName bundle:(NSBundle* )bundle error:(NSError** )error {
	NSParameterAssert(resourceName);
	NSParameterAssert(bundle);
	NSString* fileName = [bundle pathForResource:resourceName ofType:PGHelpWindowResourceType];
	if(fileName==nil) {
		// TODO set error condition
		return NO;
	}
	return [self displayHelpFromMarkdownFile:fileName error:error];
}

-(BOOL)addResource:(NSString* )resourceName bundle:(NSBundle* )bundle error:(NSError** )error {
	NSParameterAssert(resourceName);
	NSParameterAssert(bundle);
	NSString* fileName = [bundle pathForResource:resourceName ofType:PGHelpWindowResourceType];
	if(fileName==nil) {
		// TODO set error condition
		return NO;
	}
	[self addMarkdownFile:fileName];

	// reload the data
	[[self ibTableView] reloadData];

	return YES;
}

-(BOOL)addPath:(NSString* )path bundle:(NSBundle* )bundle error:(NSError** )error {
	NSParameterAssert(path);
	NSParameterAssert(bundle);
	NSString* pathName = [[bundle resourcePath] stringByAppendingPathComponent:path];
	NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:pathName];
	NSString* fileName = nil;
	while(fileName = [enumerator nextObject]) {
		if([[fileName pathExtension] isEqualToString:PGHelpWindowResourceType]) {
			[self addMarkdownFile:[pathName stringByAppendingPathComponent:fileName]];
		}
    }
	
	// reload the data
	[[self ibTableView] reloadData];
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[self files] count];
}

-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	// display only the name of the file
	NSString* fileName = [[self files] objectAtIndex:rowIndex];
	return [[fileName lastPathComponent] stringByDeletingPathExtension];
}

-(void)tableViewSelectionDidChange:(NSNotification* )notification {
    NSInteger selectedRow = [[self ibTableView] selectedRow];
    if(selectedRow >= 0 && selectedRow < [[self files] count]) {
		NSString* selectedFile = [[self files] objectAtIndex:selectedRow];
		[self displayHelpFromMarkdownFile:selectedFile error:nil];
	} else {
		NSLog(@"nothing selected");
	}
}

@end
