//
//  ItemQuizDao.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 3. 6..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "ItemQuizDao.h"
//#import "ItemQuiz.h"


@implementation ItemQuizDao
-(NSString *)setTable:(NSString *)sql{
	return [NSString stringWithFormat:sql,  @"ItemQuiz"]; 
}

// SELECT AT missionID, itemID
-(NSMutableArray *)selectAt:(NSString *)missionID ItemID:(int)itemID {
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND itemID=? ORDER BY SEQ"],missionID,[NSNumber numberWithInt:itemID]];  
	while ([rs next]) {    
		ItemQuiz *itemQuiz = [[ItemQuiz alloc] init];
		itemQuiz.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		itemQuiz.itemID = (int)[rs intForColumn:@"itemID"];
		itemQuiz.seq =(int)[rs intForColumn:@"seq"];		
		itemQuiz.quiz = (NSMutableString *)[rs stringForColumn:@"quiz"];
		itemQuiz.answer =(NSMutableString *)[rs stringForColumn:@"answer"];
		itemQuiz.probability =(int)[rs intForColumn:@"probability"];
		
		[result addObject:itemQuiz];
		[itemQuiz release];
	}
	[rs close];  

	if ([result count] == 0) {
		[result release];
		return nil;
	}

	return [result autorelease];
}

// selectWithPK
-(ItemQuiz *)selectWithPK:(NSString *)missionID ItemID:(int)itemID Seq:(int)seq{
	ItemQuiz *itemQuiz = [[ItemQuiz alloc] init];
	FMResultSet *rs = [db executeQuery:[self setTable:@"SELECT * FROM %@ WHERE missionID=? AND itemID=? AND seq=?"],
					   missionID,[NSNumber numberWithInt:itemID],[NSNumber numberWithInt:seq]];  
	if ([rs next]) { 
		//itemQuiz =  [[ItemQuiz alloc] init];
		itemQuiz.missionID = (NSMutableString *)[rs stringForColumn:@"missionID"];
		itemQuiz.itemID = (int)[rs intForColumn:@"itemID"];
		itemQuiz.seq =(int)[rs intForColumn:@"seq"];		
		itemQuiz.quiz = (NSMutableString *)[rs stringForColumn:@"quiz"];
		itemQuiz.answer =(NSMutableString *)[rs stringForColumn:@"answer"];
		itemQuiz.probability =(int)[rs intForColumn:@"probability"];
	}
	else {
		[itemQuiz release];
		return nil;
	}
	
	[rs close];
	return [itemQuiz autorelease];
}

// INSERT
-(BOOL)insert:(ItemQuiz *)itemQuiz{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"INSERT INTO %@ (missionID, itemID, seq, quiz, answer, probability) \
					   VALUES (?,?,?,?,?,?)"],
	 itemQuiz.missionID, 
	 [NSNumber numberWithInt:itemQuiz.itemID],
	 [NSNumber numberWithInt:itemQuiz.seq],
	 itemQuiz.quiz,
	 itemQuiz.answer,
	 [NSNumber numberWithInt:itemQuiz.probability]
	 ];
	
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// UPDATE
-(BOOL)update:(ItemQuiz *)itemQuiz{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"UPDATE %@ SET \
					   quiz = ?, \
					   answer = ?, \
					   probability = ? \
					   WHERE missionID=? AND itemID=? AND seq=?"], 
	 itemQuiz.quiz,
	 itemQuiz.answer,
	 [NSNumber numberWithInt:itemQuiz.probability],
	 itemQuiz.missionID, 
	 [NSNumber numberWithInt:itemQuiz.itemID],
	 [NSNumber numberWithInt:itemQuiz.seq]
	 ];
	
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;  
}

// DELETE
- (BOOL)delete:(ItemQuiz *)itemQuiz{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE missionID=? AND itemID=? AND seq=?"], 
	 itemQuiz.missionID, [NSNumber numberWithInt:itemQuiz.itemID], [NSNumber numberWithInt:itemQuiz.seq]];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

-(BOOL)delete_itemID:(NSString *)missionID ItemID:(int)itemID{
	BOOL success = YES;
	[db executeUpdate:[self setTable:@"DELETE FROM %@ WHERE missionID=? AND itemID=?"], 
		missionID, [NSNumber numberWithInt:itemID]];
	if ([db hadError]) {
		NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		success = NO;
	}  
	return success;
}

// Save
- (BOOL)save:(ItemQuiz *)itemQuiz{
	BOOL success = YES;
	
	if ([self selectWithPK:itemQuiz.missionID ItemID:itemQuiz.itemID Seq:itemQuiz.seq] != nil)
	{
		success = [self update:itemQuiz];
	}
	else 
	{
		success = [self insert:itemQuiz];
	}
	return success;
}


@end
