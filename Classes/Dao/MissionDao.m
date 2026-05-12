#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MissionDao.h"
//#import "Mission.h"

@implementation MissionDao

-(NSString *)setTable:(NSString *)sql{
	NSLog(@"%@",[NSString stringWithFormat:sql,  @"Mission"]);
	return [NSString stringWithFormat:sql,  @"Mission"]; 
}
// SELECT ALL
-(NSMutableArray *)selectAll{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@"]];  
	while ([rs next]) {    
		Mission *mission = [[Mission alloc] init];
		mission.mID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		mission.mTitle = (NSMutableString *)[rs stringForColumn:@"Title"];
		mission.mDescription =(NSMutableString *)[rs stringForColumn:@"Description"];
		mission.mPlace = (NSMutableString *)[rs stringForColumn:@"Place"];
		mission.mDesigner = (NSMutableString *)[rs stringForColumn:@"Designer"];
		mission.mStartTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		mission.mRunLimitTime = (NSDate *)[rs dateForColumn:@"RunLimitTime"];
		mission.mStatus = (int)[rs intForColumn:@"Status"];
		mission.mWriteDate = (NSDate *)[rs dateForColumn:@"WriteDate"];
		mission.mVirtual = (int)[rs intForColumn:@"Virtual"];
		mission.mQuiz = (NSMutableString *)[rs stringForColumn:@"Quiz"];
		mission.mAnswer = (NSMutableString *)[rs stringForColumn:@"Answer"];


		
		[result addObject:mission];
		[mission release];
	}
	[rs close];  
  
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result  autorelease];
}

// SELECT AT
-(Mission *)selectWithPK:(NSString *)missionID{
	Mission *mission = [[Mission alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=?"],missionID];  
	if ([rs next]) {    
		mission.mID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		mission.mTitle = (NSMutableString *)[rs stringForColumn:@"Title"];
		mission.mDescription =(NSMutableString *)[rs stringForColumn:@"Description"];
		mission.mPlace = (NSMutableString *)[rs stringForColumn:@"Place"];
		mission.mDesigner = (NSMutableString *)[rs stringForColumn:@"Designer"];
		mission.mStartTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		mission.mRunLimitTime = (NSDate *)[rs dateForColumn:@"RunLimitTime"];
    mission.mStatus = (int)[rs intForColumn:@"Status"];
		mission.mWriteDate = (NSDate *)[rs dateForColumn:@"WriteDate"];
		mission.mVirtual = (int)[rs intForColumn:@"Virtual"];
		mission.mQuiz = (NSMutableString *)[rs stringForColumn:@"Quiz"];
		mission.mAnswer = (NSMutableString *)[rs stringForColumn:@"Answer"];
		
		
	} else {
		[mission release];
		return nil;
	} 
	
	[rs close];
	return [mission autorelease];
}

// SELECT BuildingMission
-(NSMutableArray *)selectMissionStatus:(int)status{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
  
  FMResultSet *rs;
   
    rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE Status <= ? ORDER BY WriteDate DESC "], [NSNumber numberWithInt:status]];  
	while ([rs next]) {    
		Mission *mission = [[Mission alloc] init];
		mission.mID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		mission.mTitle = (NSMutableString *)[rs stringForColumn:@"Title"];
		mission.mDescription =(NSMutableString *)[rs stringForColumn:@"Description"];
		mission.mPlace = (NSMutableString *)[rs stringForColumn:@"Place"];
		mission.mDesigner = (NSMutableString *)[rs stringForColumn:@"Designer"];
		mission.mStartTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		mission.mRunLimitTime = (NSDate *)[rs dateForColumn:@"RunLimitTime"];
		mission.mStatus = (int)[rs intForColumn:@"Status"];
		mission.mWriteDate = (NSDate *)[rs dateForColumn:@"WriteDate"];
		mission.mVirtual = (int)[rs intForColumn:@"Virtual"];
		mission.mQuiz = (NSMutableString *)[rs stringForColumn:@"Quiz"];
		mission.mAnswer = (NSMutableString *)[rs stringForColumn:@"Answer"];
		
		[result addObject:mission];
		[mission release];
	}
	[rs close];  
	
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result autorelease];
}



// INSERT
-(BOOL)insert:(Mission *)mission{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"INSERT INTO %@ \
										 (missionID, \
										 Title, \
										 Description, \
										 Place, \
										 Quiz, \
										 Answer, \
										 Designer, \
										 StartTime, \
										 RunLimitTime, \
                                          Virtual, \
                                          Status, \
                                          WriteDate) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)"], 
	 mission.mID, 
	 mission.mTitle, 
	 mission.mDescription, 
	 mission.mPlace,
	 mission.mQuiz,
	 mission.mAnswer,
	 mission.mDesigner, 
	 mission.mStartTime, 
	 mission.mRunLimitTime, 
    [NSNumber numberWithInt:mission.mVirtual],
    [NSNumber numberWithInt:mission.mStatus],
     mission.mWriteDate
	 ];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}
	return success;
}

// UPDATE
-(BOOL)update:(Mission *)mission{
  BOOL success = YES;
  [db executeUpdate:[self setTable:@"UPDATE %@ SET \
										 Title = ?, \
										 Description = ?, \
										 Place = ?, \
										 Quiz = ?, \
										 Answer = ?, \
										 Designer = ?, \
										 StartTime = ?, \
										 RunLimitTime = ?, \
                                         Virtual = ?, \
                                         Status = ?, \
										 WriteDate = ? \
										 WHERE missionID=?"], 
   mission.mTitle, 
   mission.mDescription, 
   mission.mPlace, 
	 mission.mQuiz,
	 mission.mAnswer,
   mission.mDesigner, 
   mission.mStartTime, 
   mission.mRunLimitTime, 
   [NSNumber numberWithInt:mission.mVirtual],
    [NSNumber numberWithInt:mission.mStatus],
	 [NSDate date],
	 mission.mID];
  if ([db hadError]) {
    NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    success = NO;
  }  
  return success;  
}
// DELETE AT
- (BOOL)deleteAt:(NSString *)missionID{
  BOOL success = YES;
  [db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE missionID=?"], missionID];
  if ([db hadError]) {
    NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    success = NO;
  }  
  return success;
}

// DELETE
- (BOOL)delete:(Mission *)mission{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE missionID=?"], mission.mID];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// Save
- (BOOL)save:(Mission *)mission{
	BOOL success = YES;
	
	if ([self selectWithPK:mission.mID] != nil)
	{
		success = [self update:mission];
	}
	else 
	{
		success = [self insert:mission];
	}
	return success;
}

- (void)dealloc {
  [super dealloc];
}

@end
