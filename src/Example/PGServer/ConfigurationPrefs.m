
#import <PGServerKit/PGServerKit.h>
#import "ConfigurationPrefs.h"
#import "Controller.h"

@implementation ConfigurationPrefs

-(PGServerPreferences* )configuration {
	return [[self delegate] configuration];
}

-(IBAction)ibSheetOpen:(NSWindow* )window delegate:(id)sender {
	// set delegate
	[self setDelegate:sender];
	// Setup the window
	[[self ibTableView] setDataSource:self];
	[[self ibTableView] setDelegate:self];
	[[self ibTableView] reloadData];
	// resize columns to fit 100%
	[[self ibTableView] sizeToFit];
	// de-select any rows
	[[self ibTableView] deselectAll:self];
	// begin sheet
	[NSApp beginSheet:[self ibWindow] modalForWindow:window modalDelegate:self didEndSelector:@selector(endSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)ibToolbarConfigurationSheetClose:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	// Cancel and Reload buttons
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSCancelButton];
	} else {
		[NSApp endSheet:[(NSButton* )sender window] returnCode:NSOKButton];
	}
}

-(void)endSheet:(NSWindow *)theSheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[theSheet orderOut:self];
	if(returnCode==NSOKButton) {
		if([[self delegate] respondsToSelector:@selector(reloadServer)]){
#ifdef DEBUG
			NSLog(@"Saving configuration and reloading server");
#endif
			[[self configuration] save];
			[[self delegate] reloadServer];
		}
	} else {
#ifdef DEBUG
		NSLog(@"Reverting configuration");
#endif
		[[self configuration] revert];
	}
}

////////////////////////////////////////////////////////////////////////////////

-(NSInteger)numberOfRowsInTableView:(NSTableView* )aTableView {
	if([self configuration]==nil) {
		return 0;
	} else {
		return [[self configuration] count];
	}
}

-(id)tableView:(NSTableView* )aTableView objectValueForTableColumn:(NSTableColumn* )aTableColumn row:(NSInteger)rowIndex {
	NSString* theKey = [[self configuration] keyAtIndex:rowIndex];

	// key column
	if([[aTableColumn identifier] isEqual:@"key"]) {
		NSButtonCell* theCell = [aTableColumn dataCell];
		NSParameterAssert([theCell isKindOfClass:[NSButtonCell class]]);
		[theCell setTitle:theKey];
		if([[self configuration] enabledForKey:theKey]) {
			[theCell setState:NSOnState];
		} else {
			[theCell setState:NSOffState];
		}
		return theCell;
	}
	
	// value column
	if([[aTableColumn identifier] isEqual:@"value"]) {
		NSTextFieldCell* theCell = [aTableColumn dataCell];
		NSParameterAssert([theCell isKindOfClass:[NSTextFieldCell class]]);
		[theCell setStringValue:[[self configuration] valueForKey:theKey]];
		[theCell setEnabled:[[self configuration] enabledForKey:theKey]];
		return theCell;
	}
#ifdef DEBUG
	NSLog(@"Don't know what value to return for table column %@, returning nil",aTableColumn);
#endif
	return nil;
}

-(void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	NSString* theKey = [[self configuration] keyAtIndex:rowIndex];
	
	// deal with key column
	if([[aTableColumn identifier] isEqual:@"key"]) {
		NSParameterAssert([anObject isKindOfClass:[NSNumber class]]);
		[[self configuration] setEnabled:[(NSNumber* )anObject boolValue] forKey:theKey];
		return;
	}
	
	// deal with value column
	if([[aTableColumn identifier] isEqual:@"value"]) {
		NSParameterAssert([anObject isKindOfClass:[NSString class]]);		
		[[self configuration] setValue:(NSString* )anObject forKey:theKey];
		return;
	}
#ifdef DEBUG
	NSLog(@"Don't know what value to return for table column %@, returning nil",aTableColumn);
#endif
}

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSInteger selectedRow = [[self ibTableView] selectedRow];
	if(selectedRow >= 0 && selectedRow < [[self configuration] count]) {
		NSString* theKey = [[self configuration] keyAtIndex:selectedRow];
		NSString* theComment = [[self configuration] commentForKey:theKey];
		[self setIbComment:[theComment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	} else {
		[self setIbComment:@""];
	}
}

@end
