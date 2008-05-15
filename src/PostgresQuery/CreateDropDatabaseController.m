//
//  CreateDropDatabaseController.m
//  postgresql
//
//  Created by David Thorpe on 11/05/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CreateDropDatabaseController.h"
#import "main.h"

@implementation CreateDropDatabaseController

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theDatabase = nil;
	}
	return self;
}

-(void)dealloc {
	[m_theDatabase release];
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////
// properties

-(NSString* )database {
	return m_theDatabase;
}

-(void)setDatabase:(NSString* )theDatabase {
	[theDatabase retain];
	[m_theDatabase release];
	m_theDatabase = theDatabase;
}

///////////////////////////////////////////////////////////////////////////////
// outlets

-(NSWindow* )createSheet {
	return m_theCreateSheet;
}

-(NSWindow* )dropSheet {
	return m_theDropSheet;
}

///////////////////////////////////////////////////////////////////////////////
// public methods

-(void)beginCreateDatabaseWithWindow:(NSWindow* )theWindow {
	// empty database value
	[self setDatabase:@""];
	// display the sheet
	[NSApp beginSheet:[self createSheet] modalForWindow:theWindow modalDelegate:self didEndSelector:@selector(didEndCreateSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(void)beginDropDatabaseWithWindow:(NSWindow* )theWindow {
	NSLog(@"drop");
	// display the sheet
	[NSApp beginSheet:[self dropSheet] modalForWindow:theWindow modalDelegate:self didEndSelector:@selector(didEndDropSheet:returnCode:contextInfo:) contextInfo:nil];
}

///////////////////////////////////////////////////////////////////////////////
// sheet was ended

-(void)didEndCreateSheet:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];	
	if(returnCode==NSOKButton) {
		[[NSNotificationCenter defaultCenter] postNotificationName:FLXCreateDatabaseNotification object:[self database]];
		 
	}
}

-(void)didEndDropSheet:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {
		[[NSNotificationCenter defaultCenter] postNotificationName:FLXDropDatabaseNotification object:[self database]];
	}
}

///////////////////////////////////////////////////////////////////////////////
// IBAction

-(IBAction)doEndSheet:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	NSWindow* theSheet = [theButton window];
	NSInteger returnValue = NSCancelButton;
	
	// determine return value
	if([[theButton title] isEqual:@"Create"] || [[theButton title] isEqual:@"Drop"]) {
		returnValue = NSOKButton;
	}
	
	// remove the sheet
	[NSApp endSheet:theSheet returnCode:returnValue];	
}

@end
