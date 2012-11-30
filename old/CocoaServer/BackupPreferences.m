
#import "BackupPreferences.h"

@implementation BackupPreferences

////////////////////////////////////////////////////////////////////////////////

@synthesize ibMainWindow;
@synthesize ibBackupWindow;
@synthesize ibAppDelegate;
@dynamic server;
@synthesize backupPath;
@synthesize backupFrequency;
@synthesize backupThinKeepHours;
@synthesize backupThinKeepDays;
@synthesize backupThinKeepWeeks;
@synthesize backupThinKeepMonths;
@synthesize frequencySliderValue;
@synthesize frequencySliderString;

const double FLXFrequencyDynamicPower = 2.4;

////////////////////////////////////////////////////////////////////////////////
// constructors

-(void)awakeFromNib {
	// set defaults
	[self setBackupPath:NSHomeDirectory()];
	[self setBackupFrequency:(5 * 60)]; // every five mins
	[self setBackupThinKeepHours:48];
	[self setBackupThinKeepDays:28];
	[self setBackupThinKeepWeeks:52];
	[self setBackupThinKeepMonths:24];
	
	// observe frequency value changing
	[self addObserver:self forKeyPath:@"frequencySliderValue" options:NSKeyValueObservingOptionNew context:nil];
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(FLXPostgresServer* )server {
	return [FLXPostgresServer sharedServer];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSTimeInterval)frequencySliderValueToString {
	// squared to give larger dynamic range
	double f2 = pow([self frequencySliderValue],FLXFrequencyDynamicPower);
	if(f2 < 60) {
		NSUInteger mins = (NSUInteger)f2;
		if(mins==1) {
			[self setFrequencySliderString:[NSString stringWithFormat:@"every min",mins]];			
		} else {
			[self setFrequencySliderString:[NSString stringWithFormat:@"every %u mins",mins]];
		}
		return (NSTimeInterval)(mins * 60.0);
	}
	if(f2 < (60 * 24)) {
		NSUInteger hours = (NSUInteger)f2 / 60;
		if(hours==1) {
			[self setFrequencySliderString:[NSString stringWithFormat:@"every hour",hours]];
		} else {
			[self setFrequencySliderString:[NSString stringWithFormat:@"every %u hours",hours]];
		}
		return (NSTimeInterval)(hours * 3600.0);
	}
	if(f2 < (60 * 24 * 7)) {
		NSUInteger days = (NSUInteger)f2 / (60 * 24);
		if(days==1) {
			[self setFrequencySliderString:[NSString stringWithFormat:@"every day",days]];
		} else {
			[self setFrequencySliderString:[NSString stringWithFormat:@"every %u days",days]];
		}
		return (NSTimeInterval)(days * 3600.0 * 24.0);				
	}
	
	NSUInteger weeks = (NSUInteger)f2 / (60 * 24 * 7);
	if(weeks==1) {
		[self setFrequencySliderString:[NSString stringWithFormat:@"every week",weeks]];
	} else {
		[self setFrequencySliderString:[NSString stringWithFormat:@"every %u weeks",weeks]];		
	}
	return (NSTimeInterval)(weeks * 3600.0 * 24.0 * 7.0);				
}

-(void)frequencyToSliderValue {
	double mins = (double)[self backupFrequency] / 60.0;
	[self setFrequencySliderValue:pow(mins,(1.0/FLXFrequencyDynamicPower))];
	[self frequencySliderValueToString];
}

-(void)backupDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];	
	
	// set the backupFrequency value
	[self setBackupFrequency:[self frequencySliderValueToString]];
	
	if(returnCode==NSOKButton) {
		NSLog(@"TODO: Write backup prefs");
	}
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath isEqual:@"frequencySliderValue"] && [object isEqual:self]) {
		[self frequencySliderValueToString];
	}
}

////////////////////////////////////////////////////////////////////////////////

-(IBAction)doBackup:(id)sender {	
	// set initial values to display
	[self frequencyToSliderValue];

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
	NSURL* theSelectedURL = [NSURL fileURLWithPath:[self backupPath]];
	if([sender isKindOfClass:[NSPathControl class]]) {
		NSPathComponentCell* theClickedCell = [(NSPathControl* )sender clickedPathComponentCell];	
		if([theClickedCell URL]) {
			theSelectedURL = [theClickedCell URL];
		}
	}
	
	NSOpenPanel* thePanel = [NSOpenPanel openPanel];
	[thePanel setCanChooseFiles:NO];
	[thePanel setCanChooseDirectories:YES];
	[thePanel setAllowsMultipleSelection:NO]; 
	[thePanel setCanCreateDirectories:YES];
	[thePanel setDirectoryURL:theSelectedURL];
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
