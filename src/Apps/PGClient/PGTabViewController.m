
#import "PGTabViewController.h"
#import <PGControlsKit/PGControlsKit.h>

@implementation PGTabViewController


////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
    self = [super init];
    if(self) {
		_consoles = [NSMutableDictionary dictionary];
		_logs = [NSMutableDictionary dictionary];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(PGConsoleView* )_consoleForKey:(NSUInteger)key {
	NSParameterAssert(key);
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	PGConsoleView* console = [_consoles objectForKey:keyObject];
	if(console==nil) {
		console = [[PGConsoleView alloc] init];
		[console setDelegate:self];
		[console setEditable:YES];
		[console setTag:key];
		[_consoles setObject:console forKey:keyObject];
	}
	NSParameterAssert([console isKindOfClass:[PGConsoleView class]]);
	return console;
}

-(NSNumber* )_consoleIdentifierWithKey:(NSUInteger)key {
	return [NSNumber numberWithUnsignedInteger:key];
}

-(NSMutableArray* )_logForKey:(NSUInteger)key {
	NSNumber* keyObject = [NSNumber numberWithUnsignedInteger:key];
	NSMutableArray* log = [_logs objectForKey:keyObject];
	if(log==nil) {
		log = [NSMutableArray array];
		[_logs setObject:log forKey:keyObject];
	}
	return log;
}
										
////////////////////////////////////////////////////////////////////////////////
// methods

-(void)openConsoleViewWithName:(NSString* )name forKey:(NSUInteger)key {
	NSParameterAssert(name);
	PGConsoleView* console = [self _consoleForKey:key];
	id identifier = [self _consoleIdentifierWithKey:key];
	NSParameterAssert(console && identifier);
	// get existing tab item
	NSInteger itemIndex = [[self ibTabView] indexOfTabViewItemWithIdentifier:identifier];
	if(itemIndex == NSNotFound) {
		NSTabViewItem* tabViewItem = [[NSTabViewItem alloc] initWithIdentifier:identifier];
		[tabViewItem setView:[console view]];
		[tabViewItem setLabel:name];
		[[self ibTabView] addTabViewItem:tabViewItem];
	}
	[[self ibTabView] selectTabViewItemWithIdentifier:identifier];
}

-(void)appendConsoleMessage:(NSString* )message forKey:(NSUInteger)key {
	PGConsoleView* console = [self _consoleForKey:key];
	NSMutableArray* log = [self _logForKey:key];
	NSParameterAssert(message);
	NSParameterAssert(console);
	NSParameterAssert(log);
	[log addObject:message];
	[console reloadData];
	[console scrollToBottom];
}

////////////////////////////////////////////////////////////////////////////////
// PGConsoleView delegate

-(NSUInteger)numberOfRowsInConsoleView:(PGConsoleView* )view {
	NSParameterAssert(view);
	return [[self _logForKey:[view tag]] count];
}

-(NSString* )consoleView:(PGConsoleView* )view stringForRow:(NSUInteger)row {
	NSMutableArray* array = [self _logForKey:[view tag]];
	return [array objectAtIndex:row];
}

-(void)consoleView:(PGConsoleView* )view appendString:(NSString *)string {
	NSUInteger key = [view tag];
	NSLog(@"TODO: %lu append string %@",key,string);
}

@end
