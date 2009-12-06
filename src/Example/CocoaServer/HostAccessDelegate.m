
#import "HostAccessDelegate.h"

@implementation HostAccessDelegate
@synthesize window;
@synthesize ibHostAccessWindow;
@synthesize ibAppDelegate;
@synthesize ibArrayController;
@synthesize selectedIndexes;
@dynamic server;
@dynamic selectedTuple;
@dynamic canRemoveSelectedTuple;

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresServer* )server {
	return [FLXPostgresServer sharedServer];
}

-(FLXPostgresServerAccessTuple* )selectedTuple {
	// only allow single selection
	if([[self selectedIndexes] count] != 1) return nil;
	NSUInteger theIndex = [[self selectedIndexes] firstIndex];
	return [[[self ibArrayController] content] objectAtIndex:theIndex];
}

-(BOOL)canRemoveSelectedTuple {
	FLXPostgresServerAccessTuple* theTuple = [self selectedTuple];
	if(theTuple==nil) return NO;
	if([theTuple isSuperadminAccess]==YES) return NO;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)hostAccessDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];	
	
	if(returnCode==NSOKButton) {
		NSArray* theTuples = [[self ibArrayController] content];
		BOOL isSuccess = [[self server] writeAccessTuples:theTuples];
		if(isSuccess==NO) {
			[[self ibAppDelegate] addLogMessage:@"ERROR: Unable to write host access file" color:[NSColor redColor] bold:YES];
		} else {
			[[self server] reload];
		}
	}
	
	// release memory
	[[self ibArrayController] setContent:nil];
	
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// when access type switches from local to host, empty or fill address field
	if([object isKindOfClass:[FLXPostgresServerAccessTuple class]]==NO) {
		return;	
	}
	
	NSString* old = [change objectForKey:NSKeyValueChangeOldKey];
	NSString* new = [change objectForKey:NSKeyValueChangeNewKey];
	FLXPostgresServerAccessTuple* theTuple = (FLXPostgresServerAccessTuple* )object;
	
	if([keyPath isEqual:@"type"] && [old isEqual:new]==NO) {		
		if([new isEqual:@"local"]) {
			[theTuple setAddress:nil];
		} else {
			[theTuple setAddress:@"127.0.0.1/32"];
		}
	}
		
	if([keyPath isEqual:@"method"] && [old isEqual:new]==NO) {		
		if([new isEqual:@"ident"]) {
			[theTuple setOptions:@""];
		} else {
			[theTuple setOptions:nil];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

-(IBAction)doHostAccess:(id)sender {
	[[self ibHostAccessWindow] makeFirstResponder:nil];
	
	// obtain the host access list
	NSArray* theTuples = [[self server] readAccessTuples];
	if([theTuples count]==0) {
		[[self ibAppDelegate] addLogMessage:@"ERROR: Unable to read host access file" color:[NSColor redColor] bold:YES];
		return;
	}
	
	[[self ibArrayController] setContent:[[NSMutableArray alloc] initWithArray:theTuples]];
	
	// we observe certain values of host access tuples
	for(FLXPostgresServerAccessTuple* theTuple in [[self ibArrayController] content]) {
		[theTuple addObserver:self forKeyPath:@"type" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
		[theTuple addObserver:self forKeyPath:@"method" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	}		
	
	// begin display	
	[NSApp beginSheet:[self ibHostAccessWindow] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(hostAccessDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)doButton:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	
	if([[theButton title] isEqual:@"OK"]) {
		[NSApp endSheet:[self ibHostAccessWindow] returnCode:NSOKButton];
	} else {
		[NSApp endSheet:[self ibHostAccessWindow] returnCode:NSCancelButton];
	}
}


-(IBAction)doRemoveTuple:(id)sender {
	if([self canRemoveSelectedTuple]) {
		[[self ibArrayController] removeObject:[self selectedTuple]];
	}
}

-(IBAction)doInsertTuple:(id)sender {
	FLXPostgresServerAccessTuple* theTuple = [self selectedTuple];
	if(theTuple==nil || [theTuple isSuperadminAccess]) {
		theTuple = [FLXPostgresServerAccessTuple hostpassword];
	}
	// insert at end
	[[self ibArrayController] addObject:theTuple];
}

@end
