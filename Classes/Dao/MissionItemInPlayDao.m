#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MissionItemInPlayDao.h"
#import "MissionItem.h"

@implementation MissionItemInPlayDao

-(NSString *)setTable:(NSString *)sql{
	NSLog(@"%@",[NSString stringWithFormat:sql,  @"MissionItemInPlay"]);
	return [NSString stringWithFormat:sql,  @"MissionItemInPlay"]; 
}

// SELECT AT
-(NSMutableArray *)selectAt:(NSString *)missionID playerID:(NSString *)playerID
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND playerID=?"],missionID,playerID];  
	while ([rs next]) {    
		MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
		missionItemInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"MissionID"];
		missionItemInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionItemInPlay.itemID = (int)[rs intForColumn:@"itemID"];
		missionItemInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionItemInPlay.failCnt = (int)[rs intForColumn:@"FailCnt"];
		missionItemInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionItemInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		missionItemInPlay.quizSeq = (int)[rs intForColumn:@"quizSeq"];
		
		[result addObject:missionItemInPlay];
		[missionItemInPlay release];
	}
	[rs close];
	
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result autorelease];
}

// SELECT DIC AT
-(NSMutableDictionary *)selectDicAt:(NSString *)missionID playerID:(NSString *)playerID
{
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT ItemID,EndYN FROM %@ WHERE MissionID=? AND PlayerID=?"],missionID,playerID];  
	while ([rs next]) {    
		[result setValue:[rs stringForColumn:@"EndYN"] forKey:[NSString stringWithFormat:@"%d",[rs intForColumn:@"ItemID"]]];
	}
	[rs close];  
	
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result autorelease];
}

// SELECT PK
-(MissionItemInPlay *)selectWithPK:(NSString *)missionID playerID:(NSString *)playerID itemID:(int)itemID
{
	MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND playerID=? AND itemID=?"],
										 missionID,playerID,[NSNumber numberWithInt:itemID]];  
	if ([rs next]) {    
		missionItemInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionItemInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionItemInPlay.itemID = (int)[rs intForColumn:@"itemID"];
		missionItemInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionItemInPlay.failCnt = (int)[rs intForColumn:@"FailCnt"];
		missionItemInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionItemInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		missionItemInPlay.quizSeq = (int)[rs intForColumn:@"quizSeq"];
	}
	else {
		[missionItemInPlay release];
		return nil;
	}
	
	[rs close];
	return [missionItemInPlay autorelease];
}

// selectLastAcquiredItem
// 지뢰 폭발시 마지막으로 먹은 아이템 중  지뢰방지,갬블링,런스타트, 지뢰 는 제외하고 select
- (MissionItemInPlay *)selectLastAcquiredItem:(NSString *)missionID playerID:(NSString *)playerID itemID:(int)itemID
{
	MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT itemplay.* FROM %@ itemplay inner join MissionItem I \
                                                                            on itemplay.missionID = I.missionID  and itemplay.itemID = I.itemID \
																			WHERE itemplay.missionID=? AND itemplay.playerID=? \
                                                                            AND I.itemType NOT IN ('55','61','50','42') \
																			AND itemplay.endYN IN ('Y') \
                                                                            AND itemplay.itemID <> ? \
																			ORDER BY itemplay.endTime DESC"],
										 missionID,playerID,[NSNumber numberWithInt:itemID]];  
	if ([rs next]) {    
		missionItemInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionItemInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionItemInPlay.itemID = (int)[rs intForColumn:@"itemID"];
		missionItemInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionItemInPlay.failCnt = (int)[rs intForColumn:@"FailCnt"];
		missionItemInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionItemInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		missionItemInPlay.quizSeq = (int)[rs intForColumn:@"quizSeq"];
	}
	else {
		[missionItemInPlay release];
		return nil;
	}
	
	[rs close];
	return [missionItemInPlay autorelease];
}
// 가상모드 이어하기시 마지막 획득 아이템 가져오기
- (MissionItem *)loadLastAcquiredItem:(NSString *)missionID playerID:(NSString *)playerID
{
	//MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
    MissionItem *missionItem = [[MissionItem alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT I.* FROM %@ itemplay inner join MissionItem I \
                                        on itemplay.missionID = I.missionID  and itemplay.itemID = I.itemID \
                                        WHERE itemplay.missionID=? AND itemplay.playerID=? \
                                        AND itemplay.endYN IN ('Y') \
                                        ORDER BY itemplay.endTime DESC"],
                       missionID,playerID];  
	if ([rs next]) {    
		missionItem.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionItem.itemID = (int)[rs intForColumn:@"itemID"];
		missionItem.mandatory = (int)[rs intForColumn:@"mandatory"];		
		missionItem.itemType =(NSMutableString *)[rs stringForColumn:@"itemType"];
		missionItem.latitude =(CLLocationDegrees)[rs doubleForColumn:@"latitude"];
		missionItem.longitude =(CLLocationDegrees)[rs doubleForColumn:@"longitude"];
		missionItem.blackCnt = (int)[rs intForColumn:@"blackCnt"];		
		missionItem.blackTime = (int)[rs intForColumn:@"blackTime"];		
		missionItem.rangeAR =(int)[rs intForColumn:@"rangeAR"];
		missionItem.showType =(NSMutableString *)[rs stringForColumn:@"showType"];
		missionItem.effectiveRange =(int)[rs intForColumn:@"effectiveRange"];
		missionItem.effectiveTime =(int)[rs intForColumn:@"effectiveTime"];
		missionItem.itemGame =(int)[rs intForColumn:@"itemGame"];	
		missionItem.info =(NSMutableString *)[rs stringForColumn:@"info"];
		missionItem.relationItemID = (int)[rs intForColumn:@"relationItemID"];
	}
	else {
		[missionItem release];
		return nil;
	}
	
	[rs close];
	return [missionItem autorelease];
}

// selectLastFailedQuiz
-(MissionItemInPlay *)selectLastFailedQuiz:(NSString *)missionID playerID:(NSString *)playerID
{
	MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
	
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
																			WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
																			AND A.itemID = B.itemID AND B.itemType='41' AND A.endTime is NULL"],
										 missionID,playerID]; 
	if([rs next]) {
		rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
													 WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
													 AND A.itemID = B.itemID AND B.itemType='40' AND A.endYN='N' \
													 AND A.failCnt > 2 ORDER BY A.endTime DESC"],
					missionID,playerID]; 
	}
	else {
		rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
													 WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
													 AND A.itemID = B.itemID \
													 AND (B.itemType ='40' AND A.failCnt > 2 OR B.itemType ='41') \
													 AND A.endYN='N' \
													 ORDER BY A.endTime DESC"],
					missionID,playerID]; 
	}
	
	if ([rs next]) {    
		missionItemInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionItemInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionItemInPlay.itemID = (int)[rs intForColumn:@"itemID"];
		missionItemInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionItemInPlay.failCnt = (int)[rs intForColumn:@"FailCnt"];
		missionItemInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionItemInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		missionItemInPlay.quizSeq = (int)[rs intForColumn:@"quizSeq"];
	}
	else {
		[missionItemInPlay release];
		return nil;
	}
	
	[rs close];
	return [missionItemInPlay autorelease];
}

// selectLastStartedTimeOut
-(MissionItemInPlay *)selectLastStartedTimeOut:(NSString *)missionID playerID:(NSString *)playerID
{
	MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
													 WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
													 AND A.itemID = B.itemID AND B.itemType='42' AND A.endYN='N' \
													 AND A.endTime IS NOT NULL ORDER BY A.endTime DESC"],
					missionID,playerID]; 
	if ([rs next]) {    
		missionItemInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionItemInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionItemInPlay.itemID = (int)[rs intForColumn:@"itemID"];
		missionItemInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionItemInPlay.failCnt = (int)[rs intForColumn:@"FailCnt"];
		missionItemInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionItemInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		missionItemInPlay.quizSeq = (int)[rs intForColumn:@"quizSeq"];
	}
	else {
		[missionItemInPlay release];
		return nil;
	}
	
	[rs close];
	return [missionItemInPlay autorelease];
}

// IS THE ITEMTYPE ACQUIRED?
- (MissionItemInPlay *)selectlastAcquiredType:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType
{
	MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
	
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.endYN FROM MISSIONITEMINPLAY A, MISSIONITEM B \
																			WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
																			AND A.itemID = B.itemID AND B.itemType=? AND A.endYN='Y' \
																			ORDER BY A.endTime DESC"],
										 missionID,playerID,itemType]; 
	
	if ([rs next]) {    
		missionItemInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		missionItemInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionItemInPlay.itemID = (int)[rs intForColumn:@"itemID"];
		missionItemInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionItemInPlay.failCnt = (int)[rs intForColumn:@"FailCnt"];
		missionItemInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionItemInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		missionItemInPlay.quizSeq = (int)[rs intForColumn:@"quizSeq"];
	}
	else {
		[missionItemInPlay release];
		return nil;
	}
	
	[rs close];
	return [missionItemInPlay autorelease];
}

// SELECT WITH ITEMTYPE
- (NSMutableArray *)selectWithMissionID:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
																			WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
																			AND A.itemID = B.itemID AND B.itemType=?"],
										 missionID,playerID,itemType]; 
	
	while ([rs next]) {    
		MissionItemInPlay *missionItemInPlay = [[MissionItemInPlay alloc] init];
		missionItemInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"MissionID"];
		missionItemInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		missionItemInPlay.itemID = (int)[rs intForColumn:@"itemID"];
		missionItemInPlay.endYN = (NSMutableString *)[rs stringForColumn:@"EndYN"];
		missionItemInPlay.failCnt = (int)[rs intForColumn:@"FailCnt"];
		missionItemInPlay.startTime = (NSDate *)[rs dateForColumn:@"StartTime"];
		missionItemInPlay.endTime = (NSDate *)[rs dateForColumn:@"EndTime"];
		missionItemInPlay.quizSeq = (int)[rs intForColumn:@"quizSeq"];
		
		[result addObject:missionItemInPlay];
		[missionItemInPlay release];
	}
	[rs close];  
	
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result autorelease];
}

// 랜덤 획득을 위한 안먹은 아이템 배열 ( end 아이템, 랜덤,암흑,Run End 획득 아이템 제외)
- (NSMutableArray *)selectRand:(NSString *)missionID playerID:(NSString *)playerID 
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
   
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT B.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
                                        WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
                                        AND A.itemID = B.itemID AND A.EndYN ='N' AND B.itemType not in ('48','50','56')"],
                       missionID,playerID]; 
	
	while ([rs next]) {    
        MissionItem *missionItem = [[MissionItem alloc] init];
        missionItem.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
        missionItem.itemID = (int)[rs intForColumn:@"itemID"];
		missionItem.mandatory = (int)[rs intForColumn:@"mandatory"];		
		missionItem.itemType =(NSMutableString *)[rs stringForColumn:@"itemType"];
		missionItem.latitude =(CLLocationDegrees)[rs doubleForColumn:@"latitude"];
		missionItem.longitude =(CLLocationDegrees)[rs doubleForColumn:@"longitude"];
		missionItem.blackCnt = (int)[rs intForColumn:@"blackCnt"];		
		missionItem.blackTime = (int)[rs intForColumn:@"blackTime"];		
		missionItem.rangeAR =(int)[rs intForColumn:@"rangeAR"];
		missionItem.showType =(NSMutableString *)[rs stringForColumn:@"showType"];
		missionItem.effectiveRange =(int)[rs intForColumn:@"effectiveRange"];
		missionItem.effectiveTime =(int)[rs dateForColumn:@"effectiveTime"];
		missionItem.itemGame =(int)[rs intForColumn:@"itemGame"];	
		missionItem.info =(NSMutableString *)[rs stringForColumn:@"info"];
		missionItem.relationItemID = (int)[rs intForColumn:@"relationItemID"];
        
		[result addObject:missionItem];
		[missionItem release];
	}
	[rs close];  
	
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result autorelease];
}


// selectQuiz20Seq
- (int)selectQuiz20Seq:(NSString *)missionID playerID:(NSString *)playerID
{
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
																			WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
																			AND A.itemID = B.itemID AND B.itemType='41' AND A.QuizSeq > 0"],
										 missionID,playerID]; 
	
	if ([rs next]) {
	    [rs close];    
        return (int)[rs intForColumn:@"quizSeq"];
	}
	else {
	    [rs close];
	    return 0;
	}
}

// selectAcquiredQuiz20
- (NSMutableArray *)selectAcquiredQuiz20:(NSString *)missionID playerID:(NSString *)playerID
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT C.* FROM MISSIONITEMINPLAY A, MISSIONITEM B, ItemQuiz C \
																			WHERE A.missionID=? AND A.playerID=? AND A.EndYN = 'Y' \
																			AND A.missionID = B.missionID \
																			AND A.itemID = B.itemID AND B.itemType='41' \
																			AND A.missionID = C.missionID AND A.itemID = C.itemID \
																			AND A.QuizSeq = C.seq \
																			ORDER BY A.endTime"],
										 missionID,playerID]; 
	
	while ([rs next]) {    
		[result addObject:(NSMutableString *)[rs stringForColumn:@"quiz"]];
	}
	[rs close];  
	
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result autorelease];
}

// missionCompleted
-(BOOL)missionCompleted:(NSString *)missionID playerID:(NSString *)playerID
{
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
																			WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
																			AND A.itemID = B.itemID AND B.mandatory = 1 \
																			AND A.endYN = 'N'"],missionID,playerID]; 
	if ([rs next]) {    
		[rs close];  
		return NO;
	} else {
		[rs close];  
		return YES;
	}
}

// missionCompletedExceptEndItem
-(BOOL)missionCompletedExceptEndItem:(NSString *)missionID playerID:(NSString *)playerID
{
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT A.* FROM MISSIONITEMINPLAY A, MISSIONITEM B \
																			WHERE A.missionID=? AND A.playerID=? AND A.missionID = B.missionID \
																			AND A.itemID = B.itemID AND B.mandatory = 1 AND B.itemType <> '48' \
																			AND A.endYN = 'N'"],missionID,playerID]; 
	if ([rs next]) {    
		[rs close];  
		return NO;
	} else {
		[rs close];  
		return YES;
	}
}


// INSERT
-(BOOL)insert:(MissionItemInPlay *)missionItemInPlay{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"INSERT INTO %@ \
										 (MissionID, \
										 PlayerID, \
										 ItemID, \
										 EndYN, \
										 FailCnt, \
										 StartTime, \
										 EndTime, \
										 QuizSeq) VALUES (?,?,?,?,?,?,?,?)"], 
	 missionItemInPlay.missionID, 
	 missionItemInPlay.playerID, 
	 [NSNumber numberWithInt:missionItemInPlay.itemID], 
	 missionItemInPlay.endYN, 
	 [NSNumber numberWithInt:missionItemInPlay.failCnt], 
	 missionItemInPlay.startTime, 
	 missionItemInPlay.endTime, 
	 missionItemInPlay.quizSeq
	 ];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// UPDATE
-(BOOL)update:(MissionItemInPlay *)missionItemInPlay{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"UPDATE %@ SET \
										 EndYN = ?, \
										 FailCnt = ?, \
										 StartTime = ?, \
										 EndTime = ?, \
										 QuizSeq = ? \
										 WHERE MissionID=? \
										 AND PlayerID=? \
										 AND ItemID=?"],  
	 missionItemInPlay.endYN, 
	 [NSNumber numberWithInt:missionItemInPlay.failCnt],
	 missionItemInPlay.startTime, 
	 missionItemInPlay.endTime, 
     [NSNumber numberWithInt:missionItemInPlay.quizSeq],
	 missionItemInPlay.missionID,
	 missionItemInPlay.playerID, 
	 [NSNumber numberWithInt:missionItemInPlay.itemID]
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
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE MissionID=? AND PlayerID=?"], 
	 missionID, playerID];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// DELETE AT
- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID itemID:(int)itemID
{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE MissionID=? AND PlayerID=? AND ItemID=?"], 
	 missionID, playerID, [NSNumber numberWithInt:itemID]];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// DELETE
- (BOOL)delete:(MissionItemInPlay *)missionItemInPlay{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE MissionID=? AND PlayerID=? AND ItemID=?"], 
	 missionItemInPlay.missionID, missionItemInPlay.playerID, [NSNumber numberWithInt:missionItemInPlay.itemID]];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// Save
- (BOOL)save:(MissionItemInPlay *)missionItemInPlay{
	BOOL success = YES;
	
	if ([self selectWithPK:missionItemInPlay.missionID playerID:missionItemInPlay.playerID itemID:missionItemInPlay.itemID] != nil)
	{
		success = [self update:missionItemInPlay];
	}
	else 
	{
		success = [self insert:missionItemInPlay];
	}
	return success;
}

- (void)dealloc {
	[super dealloc];
}

@end
