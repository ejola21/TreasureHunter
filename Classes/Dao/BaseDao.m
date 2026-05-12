#import "TreasureHunterAppDelegate.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "BaseDao.h"

@implementation BaseDao
@synthesize db;

-(TreasureHunterAppDelegate *)appDeligate;
{
	return (TreasureHunterAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (id)init{
  if(self = [super init]){
    db = [[[self appDeligate] db] retain];  
	//	db = [APPDEL db];
  }
  return self;
}

-(NSString *)setTable:(NSString *)sql{  
  return NULL;
}

- (void)dealloc {
  [db release];
  [super dealloc];
}

@end
