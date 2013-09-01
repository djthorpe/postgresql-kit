
@protocol PGPasswordWindowDelegate <NSObject>
@required
-(void)passwordWindow:(PGPasswordWindow* )windowController endedWithStatus:(NSInteger)status contextInfo:(void* )contextInfo;
@end

@interface PGPasswordWindow : NSWindowController

// properties
@property BOOL saveToKeychain;
@property NSString* passwordField;
@property (weak,nonatomic) id<PGPasswordWindowDelegate> delegate;

// methods
-(void)beginSheetForParentWindow:(NSWindow* )parentWindow contextInfo:(void* )contextInfo;

// actions
-(IBAction)ibEndSheetForButton:(id)sender;

@end
