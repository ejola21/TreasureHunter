//
//  ItemRnPInPlayDao.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 5. 7..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "ItemRnPInPlayDao.h"
#import "ItemRnPInPlay.h"

@implementation ItemRnPInPlayDao

-(NSString *)setTable:(NSString *)sql{
	NSLog(@"%@",[NSString stringWithFormat:sql,  @"ItemRnPInPlay"]);
	return [NSString stringWithFormat:sql,  @"ItemRnPInPlay"]; 
}

- (ItemRnPInPlay *)selectWithPK:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType
{
	ItemRnPInPlay *itemRnPInPlay = [[ItemRnPInPlay alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND playerID=? AND itemType=?"],
										 missionID,playerID,itemType];  
	if ([rs next]) {    
		itemRnPInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		itemRnPInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		itemRnPInPlay.itemType = (NSMutableString *)[rs stringForColumn:@"ItemType"];
		itemRnPInPlay.ableCnt =(int)[rs intForColumn:@"AbleCnt"];		
		itemRnPInPlay.acquiredTime = (NSDate *)[rs dateForColumn:@"AbleTime"];
		itemRnPInPlay.acquiredTime = (NSDate *)[rs dateForColumn:@"acquiredTime"];		
	}
	else {
		[itemRnPInPlay release];
		return nil;
	}
	
	[rs close];
	return [itemRnPInPlay autorelease];
}
/*
- (ItemRnPInPlay *)selectByReward:(NSString *)missionID playerID:(NSString *)playerID rewardCode:(NSString *)rewardCode
{
	ItemRnPInPlay *itemRnPInPlay = [[ItemRnPInPlay alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ \
																			WHERE missionID=? AND playerID=? AND rewardCode=? \
																			  AND acquiredYN='Y' \
																			ORDER BY acquiredTime"],
										 missionID,playerID,rewardCode];  
	if ([rs next]) {    
		itemRnPInPlay.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		itemRnPInPlay.playerID = (NSMutableString *)[rs stringForColumn:@"PlayerID"];
		itemRnPInPlay.itemType = (int)[rs intForColumn:@"itemType"];
		itemRnPInPlay.ableCnt =(int)[rs intForColumn:@"ableCnt"];		
		itemRnPInPlay.acquiredTime = (NSDate *)[rs dateForColumn:@"ableTime"];
		itemRnPInPlay.acquiredTime = (NSDate *)[rs dateForColumn:@"acquiredTime"];
		
	}
	else {
		[itemRnPInPlay release];
		return nil;
	}
	
	[rs close];
	return [itemRnPInPlay autorelease];
}
*/
- (NSMutableDictionary *)selectDicAt:(NSString *)missionID playerID:(NSString *)playerID
{
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT itemType,ableCnt FROM %@ \
																			WHERE MissionID=? AND PlayerID=? AND ableCnt > 0 "],missionID,playerID];  
	while ([rs next]) {    
        [result setObject:[NSNumber numberWithInt:(int)[rs intForColumn:@"ableCnt"]] forKey:(NSMutableString *)[rs stringForColumn:@"ItemType"]];
		
	}
	[rs close];  
	
	return [result autorelease];
}


- (BOOL)rnpTaken:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType
{
	FMResultSet *rs;
	rs = [db executeQuery:[self setTable:@"SELECT A.* FROM %@ A \
													 WHERE A.missionID=? AND A.playerID=? AND A.itemType=? "]
													 ,missionID,playerID,itemType]; 
	
	if ([rs next]) {    
		[rs close];  
		return YES;
	} else {
		[rs close];  
		return NO;
	}
	
}

- (NSMutableArray *)selectAcquiredRnP:(NSString *)missionID playerID:(NSString *)playerID
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs;
	rs = [db executeQuery:[self setTable:@"SELECT A.* FROM %@ A \
													 WHERE A.MissionID=? AND A.PlayerID=? \
													 ORDER BY A.ItemType"],missionID,playerID]; 
	
	while ([rs next]) {    
		[result addObject:(NSMutableString *)[rs stringForColumn:@"itemType"]];
	}
	[rs close];  
	
	if ([result count] == 0) {
		[result release];
		return nil;
	}
	
	return [result autorelease];
}

- (BOOL)insert:(ItemRnPInPlay *)itemRnPInPlay
{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"INSERT INTO %@ \
										 (MissionID, \
										 PlayerID, \
										 ItemType, \
										 AbleCnt, \
										 AbleTime, \
										 AcquiredTime) VALUES (?,?,?,?,?,?)"], 
	 itemRnPInPlay.missionID, 
	 itemRnPInPlay.playerID, 
     itemRnPInPlay.itemType, 
	 [NSNumber numberWithInt:itemRnPInPlay.ableCnt],
	 itemRnPInPlay.ableTime,
	 itemRnPInPlay.acquiredTime 
	 ];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	
	return success;
}

- (BOOL)update:(ItemRnPInPlay *)itemRnPInPlay
{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"UPDATE %@ SET \
										 AbleCnt = ?, \
										 AbleTime = ?, \
										 AcquiredTime = ? \
										 WHERE MissionID=? \
										 AND PlayerID=? \
										 AND ItemType=?"],  
	 [NSNumber numberWithInt:itemRnPInPlay.ableCnt],
     itemRnPInPlay.ableTime, 
	 itemRnPInPlay.acquiredTime, 
	 itemRnPInPlay.missionID,
	 itemRnPInPlay.playerID, 
     itemRnPInPlay.itemType
	 ];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;  
}

- (BOOL)save:(ItemRnPInPlay *)itemRnPInPlay
{
	BOOL success = YES;
	
	if ([self selectWithPK:itemRnPInPlay.missionID playerID:itemRnPInPlay.playerID itemType:itemRnPInPlay.itemType] != nil)
	{
		success = [self update:itemRnPInPlay];
	}
	else 
	{
		success = [self insert:itemRnPInPlay];
	}
	return success;
}

- (BOOL)deleteAt:(NSString *)missionID playerID:(NSString *)playerID itemType:(NSString *)itemType
{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE MissionID=? AND PlayerID=? AND ItemType=?"], 
	 missionID, playerID,itemType];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

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

- (BOOL)delete:(ItemRnPInPlay *)itemRnPInPlay
{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE MissionID=? AND PlayerID=? AND ItemType=?"], 
	 itemRnPInPlay.missionID, itemRnPInPlay.playerID, itemRnPInPlay.itemType];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}


- (void)dealloc {
    [super dealloc];
}

@end
