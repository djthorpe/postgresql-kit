
#import "HostAccessDelegate.h"

@implementation HostAccessDelegate
@synthesize ibMainWindow;
@synthesize ibHostAccessWindow;
@synthesize ibAppDelegate;
@synthesize ibArrayController;
@synthesize selectedIndexes;
@dynamic server;
@dynamic selectedTuple;
@dynamic selectedTupleIndex;
@dynamic canRemoveSelectedTuple;
@synthesize tuples;

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresServer* )server {
	return [FLXPostgresServer sharedServer];
}

-(NSUInteger)selectedTupleIndex {
	if([[self selectedIndexes] count] != 1) {
		return NSNotFound;
	} else {
		return [[self selectedIndexes] firstIndex];
	}
}

-(FLXPostgresServerAccessTuple* )selectedTuple {
	// only allow single selection
	NSUInteger theIndex = [self selectedTupleIndex];
	if(theIndex==NSNotFound) {
		return nil;
	} else {
		return [[self tuples] objectAtIndex:theIndex];
	}
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
		BOOL isSuccess = [[self server] writeAccessTuples:[self tuples]];
		if(isSuccess==NO) {
			[[self ibAppDelegate] addLogMessage:@"ERROR: Unable to write host access file" color:[NSColor redColor] bold:YES];
		} else {
			[[self server] reload];
		}
	}
	
	// release memory
	[[self tuples] removeAllObjects];
	
}

-(void)observeTuple:(FLXPostgresServerAccessTuple* )theTuple {	
	[theTuple addObserver:self forKeyPath:@"type" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
	[theTuple addObserver:self forKeyPath:@"method" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];		
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
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
	
	// obtain the host access list
	NSArray* theTuples = [[self server] readAccessTuples];
	if([theTuples count]==0) {
		[[self ibAppDelegate] addLogMessage:@"ERROR: Unable to read host access file" color:[NSColor redColor] bold:YES];
		return;
	}
	
	[self setTuples:[NSMutableArray arrayWithArray:theTuples]];
	 
	// we observe certain values of host access tuples
	for(FLXPostgresServerAccessTuple* theTuple in [self tuples]) {
		[self observeTuple:theTuple];
	}
	
	// empty selection
	[[self ibArrayController] setSelectionIndexes:[NSIndexSet indexSet]];
	
	// begin display	
	[NSApp beginSheet:[self ibHostAccessWindow] modalForWindow:[self ibMainWindow] modalDelegate:self didEndSelector:@selector(hostAccessDidEnd:returnCode:contextInfo:) contextInfo:nil];
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
		[[self ibArrayController] removeObjectAtArrangedObjectIndex:[self selectedTupleIndex]];
	}
	
	// empty selection
	[[self ibArrayController] setSelectionIndexes:[NSIndexSet indexSet]];
}

-(IBAction)doInsertTuple:(id)sender {
	FLXPostgresServerAccessTuple* theTuple = [[self selectedTuple] copy];
	if(theTuple==nil || [theTuple isSuperadminAccess]) {
		// generate a new tuple
		theTuple = [FLXPostgresServerAccessTuple hostpassword];
	}

	// find the insert location, insert the tuple
	NSUInteger theIndex = [self selectedTupleIndex];
	if(theIndex==NSNotFound) {
		theIndex = [[self tuples] count] - 1;
	}
	[[self ibArrayController] insertObject:theTuple atArrangedObjectIndex:(theIndex+1)];		
	
	// observe tuple
	[self observeTuple:theTuple];
	
	// select the new tuple
	[[self ibArrayController] setSelectionIndex:(theIndex+1)];
}

@end
