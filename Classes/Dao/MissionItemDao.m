#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "MissionItemDao.h"
//#import "MissionItem.h"

@implementation MissionItemDao

-(NSString *)setTable:(NSString *)sql{
	NSLog(@"%@",[NSString stringWithFormat:sql,  @"MissionItem"]);
	
	return [NSString stringWithFormat:sql,  @"MissionItem"]; 
}

// SELECT AT missionID
-(NSMutableArray *)selectAt:(NSString *)missionID{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=?"],missionID];  
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
		missionItem.effectiveTime =(int)[rs intForColumn:@"effectiveTime"];
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

// selectWithPK
-(MissionItem *)selectWithPK:(NSString *)missionID ItemID:(int)itemID{
	//NSLog(@"missionID:%@,itemID:%d",missionID,itemID);
	MissionItem *missionItem = [[MissionItem alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND itemID=?"],
										 missionID,[NSNumber numberWithInt:itemID]];  
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

// startItemExists
-(BOOL)startItemExists:(NSString *)missionID
{
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND itemType = '49'"],missionID];  
	if([rs next]) {    
		[rs close];  
		return YES;
	}
	else {
		[rs close];  
		return NO;
	}
}

// INSERT
-(BOOL)insert:(MissionItem *)missionItem{
	BOOL success = YES;
	
	[db executeUpdate:[self setTable:@"INSERT INTO %@ (missionID, itemID, mandatory, itemType, latitude, longitude, blackCnt, blackTime, \
										 rangeAR, showType, effectiveRange, effectiveTime, itemGame,info,relationItemID) \
										 VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"],
	 missionItem.missionID, 
	 [NSNumber numberWithInt:missionItem.itemID],
	 [NSNumber numberWithInt:missionItem.mandatory],
	 missionItem.itemType,
	 [NSNumber numberWithDouble:missionItem.latitude],
	 [NSNumber numberWithDouble:missionItem.longitude],
	 [NSNumber numberWithInt:missionItem.blackCnt],
	 [NSNumber numberWithInt:missionItem.blackTime],
	 [NSNumber numberWithInt:missionItem.rangeAR],
	 missionItem.showType,
	 [NSNumber numberWithInt:missionItem.effectiveRange],
	 [NSNumber numberWithInt:missionItem.effectiveTime],
	 [NSNumber numberWithInt:missionItem.itemGame],
	 missionItem.info,
	 [NSNumber numberWithInt:missionItem.relationItemID]];
	
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}
  return success;
}

// UPDATE
-(BOOL)update:(MissionItem *)missionItem{
	BOOL success = YES;
    
//    NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
//    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSDate *date = [dateFormat dateFromString:missionItem.effectiveTime];  
    
	[db executeUpdate:[self setTable:@"UPDATE %@ SET \
										 itemType = ?, \
										 mandatory = ?, \
										 latitude = ?, \
										 longitude = ?, \
										 blackCnt = ?, \
										 blackTime = ?, \
										 rangeAR = ?, \
										 showType =  ?, \
										 effectiveRange = ?, \
										 effectiveTime = ?, \
										 itemGame = ?, \
										 info = ?, \
										 relationItemID = ?,	\
										 WriteDate = ?	\
										 WHERE missionID=? AND itemID=?"], 
	 missionItem.itemType, 
	 [NSNumber numberWithInt:missionItem.mandatory],
	 [NSNumber numberWithDouble:missionItem.latitude],
	 [NSNumber numberWithDouble:missionItem.longitude],
	 [NSNumber numberWithInt:missionItem.blackCnt],
	 [NSNumber numberWithInt:missionItem.blackTime],
	 [NSNumber numberWithInt:missionItem.rangeAR],
	 missionItem.showType,
	 [NSNumber numberWithInt:missionItem.effectiveRange],
     [NSNumber numberWithInt:missionItem.effectiveTime],
 	 [NSNumber numberWithInt:missionItem.itemGame],
	 missionItem.info,
	 [NSNumber numberWithInt:missionItem.relationItemID],
	 [NSDate date],
	 missionItem.missionID, 
	 [NSNumber numberWithInt:missionItem.itemID]];
	
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;  
}

// DELETE
- (BOOL)delete:(MissionItem *)missionItem{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE missionID=? AND itemID=?"], missionItem.missionID,[NSNumber numberWithInt:missionItem.itemID]];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

-(int)selecAtMaxItemID:(NSMutableString *)missionID
{
	int itemID = 1;
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT Max(itemID) itemID FROM %@ WHERE missionID=? "],missionID];  
	if ([rs next]) 
	{    
		itemID = (int)[rs intForColumn:@"itemID"]+1;
	}
	[rs close];
	return itemID;
}

-(NSMutableArray *)selecAtItemType:(NSMutableString *)missionID ItemType:(int)itemType
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT itemID FROM %@ WHERE missionID=? and itemType = ?"],missionID,[NSNumber numberWithInt:itemType]];  
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
		missionItem.effectiveTime =(int)[rs intForColumn:@"effectiveTime"];
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


// Save
- (BOOL)save:(MissionItem *)missionItem{
	BOOL success = YES;
	
	if ([self selectWithPK:missionItem.missionID ItemID:missionItem.itemID] != nil)
	{
		success = [self update:missionItem];
	}
	else 
	{
		success = [self insert:missionItem];
	}
	return success;
}


@end
