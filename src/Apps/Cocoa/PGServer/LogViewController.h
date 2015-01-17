
#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface LogViewController : ViewController {
	IBOutlet NSTextView* _textView;
}

// actions
-(IBAction)doClearLog:(id)sender;

@end
