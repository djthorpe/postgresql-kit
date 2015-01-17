
#import <Cocoa/Cocoa.h>

@interface AppAbout : NSObject {
	IBOutlet NSWindow* _mainWindow;
	IBOutlet NSWindow* _sheetWindow;
}

// properties
@property (readonly) NSString* title;
@property (readonly) NSAttributedString* notice;

// actions
-(IBAction)ibSheetStart:(id)sender;
-(IBAction)ibSheetEnd:(id)sender;

@end
