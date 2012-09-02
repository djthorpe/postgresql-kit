
#import <PGServerKit/PGServerKit.h>

@interface PGServer (Backup)
-(NSString* )backupToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword;
//-(BOOL)backupInBackgroundToFolderPath:(NSString* )thePath superPassword:(NSString* )thePassword;
@end
