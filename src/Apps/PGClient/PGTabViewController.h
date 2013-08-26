
#import <Cocoa/Cocoa.h>
#import <PGControlsKit/PGControlsKit.h>

@interface PGTabViewController : NSObject <PGConsoleViewDelegate> {
	NSMutableDictionary* _consoles;
	NSMutableDictionary* _logs;
}

// properties
@property (assign) IBOutlet NSTabView* ibTabView;

// methods
-(void)openConsoleViewWithName:(NSString* )name forKey:(NSUInteger)key;
-(void)appendConsoleMessage:(NSString* )message forKey:(NSUInteger)key;

@end
