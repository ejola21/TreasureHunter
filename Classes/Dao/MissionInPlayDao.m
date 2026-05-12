#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MissionInPlayDao.h"

@implementation MissionInPlayDao

-(NSString *)setTable:(NSString *)sql{
	NSLog(@"%@",[NSString stringWithFormat:sql,  @"MissionInPlay"]);
	return [NSString stringWithFormat:sql,  @"MissionInPlay"]; 
}
// SELECT ALL
-(NSMutableArray *)selectAll{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@"]];  
	while ([rs next]) {    
		MissionInPlay *missionInPlay = [[MissionInPlay alloc] init];
		missionInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionInPlay.startYN =(NSMutableString *)[rs stringForColumn:@"StartYN"];
		missionInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		
		[result addObject:missionInPlay];
		[missionInPlay release];
	}
	[rs close];  

	if ([result count] == 0) {
		[result release];
		return nil;
	}

	return [result autorelease];
}

// SELECT AT
-(MissionInPlay *)selectWithPK:(NSString *)missionID playerID:(NSString *)playerID
{
	MissionInPlay *missionInPlay = [[MissionInPlay alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND playerID=?"],missionID,playerID];  
	if ([rs next]) {    
		missionInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionInPlay.startYN =(NSMutableString *)[rs stringForColumn:@"StartYN"];
		missionInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		
	}
	else {
		[missionInPlay release];
		return nil;
	}
	
	[rs close];
	return [missionInPlay autorelease];
}

// missionStarted
-(BOOL)missionStarted:(NSString *)missionID playerID:(NSString *)playerID
{
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.* FROM %@ A \
																			WHERE A.missionID=? AND A.playerID=? \
																			AND A.startYN = 'Y'"],missionID,playerID]; 
	if ([rs next]) {    
		[rs close];  
		return YES;
	} else {
		[rs close];  
		return NO;
	}
}

// INSERT
-(BOOL)insert:(MissionInPlay *)missionInPlay{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"INSERT INTO %@ \
					   (MissionID, \
					   PlayerID, \
					   StartYN, \
					   EndYN, \
					   StartTime, \
					   EndTime) VALUES (?,?,?,?,?,?)"], 
	 missionInPlay.missionID, 
	 missionInPlay.playerID, 
	 missionInPlay.startYN, 
	 missionInPlay.endYN, 
	 missionInPlay.startTime, 
	 missionInPlay.endTime 
	 ];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// UPDATE
-(BOOL)update:(MissionInPlay *)missionInPlay{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"UPDATE %@ SET \
					   StartYN = ?, \
					   EndYN = ?, \
					   StartTime = ?, \
					   EndTime = ? \
					   WHERE MissionID=? \
					     AND PlayerID=?"], 
	 missionInPlay.startYN, 
	 missionInPlay.endYN, 
	 missionInPlay.startTime, 
	 missionInPlay.endTime, 
	 missionInPlay.missionID,
	 missionInPlay.playerID 
	 ];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;  
}
// DELETE AT
- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID
{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE MissionID=? AND PlayerID=?"], missionID, playerID];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// DELETE
- (BOOL)delete:(MissionInPlay *)missionInPlay{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE MissionID=? AND PlayerID=?"], missionInPlay.missionID, missionInPlay.playerID];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// Save
- (BOOL)save:(MissionInPlay *)missionInPlay{
	BOOL success = YES;
	
	if ([self selectWithPK:missionInPlay.missionID playerID:missionInPlay.playerID] != nil)
	{
		success = [self update:missionInPlay];
	}
	else 
	{
		success = [self insert:missionInPlay];
	}
	return success;
}

- (void)dealloc {
	[super dealloc];
}

@end
