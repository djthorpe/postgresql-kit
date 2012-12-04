
#import <Cocoa/Cocoa.h>

@interface Bindings : NSObject {
	IBOutlet NSWindow* ibMainWindow;
	IBOutlet NSWindow* ibSelectWindow;
	IBOutlet NSWindow* ibAccessWindow;
	IBOutlet NSTextView* ibOutput;
	IBOutlet NSTextField* ibInput;
	
	NSArray* databases;
	NSIndexSet* selectedDatabaseIndex;
}

@property (retain) NSArray* databases;
@property (retain) NSIndexSet* selectedDatabaseIndex;

-(NSWindow* )mainWindow;
-(NSWindow* )selectWindow;
-(NSWindow* )accessWindow;
-(void)clearOutput;
-(void)appendOutputString:(NSString* )theString color:(NSColor* )theColor bold:(BOOL)isBold;
-(void)setInputEnabled:(BOOL)isEnabled;
-(NSString* )inputString;
-(void)setInputString:(NSString* )theString;

@end
