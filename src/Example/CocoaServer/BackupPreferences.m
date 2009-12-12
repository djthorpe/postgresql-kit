
#import "BackupPreferences.h"

@implementation BackupPreferences

////////////////////////////////////////////////////////////////////////////////

@synthesize ibMainWindow;
@synthesize ibBackupWindow;
@synthesize ibAppDelegate;
@dynamic server;
@synthesize backupPath;
@synthesize frequency;
@synthesize frequencyAsString;

////////////////////////////////////////////////////////////////////////////////
// constructors

-(void)awakeFromNib {
	[self setBackupPath:NSHomeDirectory()];
	[self setFrequency:5.0]; // every five mins

	// observe frequency value changing
	[self addObserver:self forKeyPath:@"frequency" options:NSKeyValueObservingOptionNew context:nil];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresServer* )server {
	return [FLXPostgresServer sharedServer];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_setFrequencyAsString {
	// squared to give larger dynamic range
	double f2 = pow([self frequency],2.4);
	if(f2 < 60) {
		NSUInteger mins = (NSUInteger)f2;
		if(mins==1) {
			[self setFrequencyAsString:[NSString stringWithFormat:@"every min",mins]];			
		} else {
			[self setFrequencyAsString:[NSString stringWithFormat:@"every %u mins",mins]];
		}
		return;
	}
	if(f2 < (60 * 24)) {
		NSUInteger hours = (NSUInteger)f2 / 60;
		if(hours==1) {
			[self setFrequencyAsString:[NSString stringWithFormat:@"every hour",hours]];
		} else {
			[self setFrequencyAsString:[NSString stringWithFormat:@"every %u hours",hours]];
		}
		return;				
	}
	if(f2 < (60 * 24 * 7)) {
		NSUInteger days = (NSUInteger)f2 / (60 * 24);
		if(days==1) {
			[self setFrequencyAsString:[NSString stringWithFormat:@"every day",days]];
		} else {
			[self setFrequencyAsString:[NSString stringWithFormat:@"every %u days",days]];
		}
		return;				
	}
	
	NSUInteger weeks = (NSUInteger)f2 / (60 * 24 * 7);
	if(weeks==1) {
		[self setFrequencyAsString:[NSString stringWithFormat:@"every week",weeks]];
	} else {
		[self setFrequencyAsString:[NSString stringWithFormat:@"every %u weeks",weeks]];		
	}
	return;				
}

-(void)backupDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];	
	
	if(returnCode==NSOKButton) {
		NSLog(@"TODO: Write backup prefs");
	}
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath isEqual:@"frequency"] && [object isEqual:self]) {
		[self _setFrequencyAsString];
	}
}

////////////////////////////////////////////////////////////////////////////////

-(IBAction)doBackup:(id)sender {		
	// begin display	
	[NSApp beginSheet:[self ibBackupWindow] modalForWindow:[self ibMainWindow] modalDelegate:self didEndSelector:@selector(backupDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)doButton:(id)sender {
	NSButton* theButton = (NSButton* )sender;
	NSParameterAssert([theButton isKindOfClass:[NSButton class]]);
	
	if([[theButton title] isEqual:@"OK"]) {
		[NSApp endSheet:[self ibBackupWindow] returnCode:NSOKButton];
	} else {
		[NSApp endSheet:[self ibBackupWindow] returnCode:NSCancelButton];
	}
}

-(IBAction)doBackupPath:(id)sender {
	NSOpenPanel* thePanel = [NSOpenPanel openPanel];
	[thePanel setCanChooseFiles:NO];
	[thePanel setCanChooseDirectories:YES];
	[thePanel setAllowsMultipleSelection:NO]; 
	[thePanel setCanCreateDirectories:YES];
	[thePanel setDirectoryURL:[NSURL fileURLWithPath:[self backupPath]]];
	[thePanel beginSheetModalForWindow:[self ibBackupWindow] completionHandler:
	  ^(NSInteger returnCode) {
		  switch (returnCode) {
			  case NSFileHandlingPanelOKButton:
				  if([[thePanel URLs] count]) {
					  [self setBackupPath:[[[thePanel URLs] objectAtIndex:0] path]];
				  }
				  break;
			  default:
				  break;
		  }}];
}

@end
