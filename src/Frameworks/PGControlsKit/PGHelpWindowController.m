
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
@property (readonly) NSMutableAttributedString* text;

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
		_text = [NSMutableAttributedString new];
		NSParameterAssert(_text);
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


////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSData* )htmlDataFromFile:(NSString* )fileName stringEncoding:(NSStringEncoding)stringEncoding error:(NSError** )error {
	NSString* string = [NSString stringWithContentsOfFile:fileName encoding:stringEncoding error:error];
	if(string==nil) {
		return nil;
	}
	NSString* htmlString = [MMMarkdown HTMLStringWithMarkdown:string extensions:MMMarkdownExtensionsGitHubFlavored error:error];
	if(htmlString==nil) {
		return nil;
	}
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
		[[self window] makeKeyWindow];
	} else {
		[[self window] orderOut:self];
	}
}

-(BOOL)displayHelpFromMarkdownFile:(NSString* )fileName error:(NSError** )error {
	NSData* data = [self htmlDataFromFile:fileName error:error];
	if(data==nil) {
		return NO;
	}
	NSDictionary* attributes = [self documentAttributes];
	NSAttributedString* htmlAttributedString = [[NSAttributedString alloc] initWithHTML:data documentAttributes:&attributes];
	[[self text] appendAttributedString:htmlAttributedString];
	[self setVisible:YES];
	return YES;
}

-(BOOL)displayHelpFromMarkdownResource:(NSString* )resourceName bundle:(NSBundle* )bundle error:(NSError** )error {
	NSParameterAssert(resourceName);
	NSParameterAssert(bundle);
	NSString* fileName = [bundle pathForResource:resourceName ofType:PGHelpWindowResourceType];
	NSParameterAssert(fileName);
	return [self displayHelpFromMarkdownFile:fileName error:error];
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return 1;
}

-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return @"About";
}

@end
