
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>

@interface HostAccessDelegate : NSObject {
    // IBOutlets
	NSWindow* window;
	NSWindow* ibHostAccessWindow;
		
	// array of host access tuples
	NSMutableArray* hostAccessTuples;
	NSIndexSet* selectedHostAccessTuples;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSWindow* ibHostAccessWindow;

// properties
@property (retain) NSMutableArray* hostAccessTuples;

// bindings
@property (assign) NSIndexSet* selectedHostAccessTuples;

// IB Actions
-(IBAction)doHostAccess:(id)sender;
-(IBAction)doHostAccessButton:(id)sender;
-(IBAction)doRemoveHostAccessTuple:(id)sender;
-(IBAction)doInsertHostAccessTuple:(id)sender;

@end
