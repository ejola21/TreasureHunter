//
//  MissionItem.m
//  TreasureHunter
//
//  Created by noh jh on 11. 2. 13..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MissionItem.h"
#import "TreasureHunterAppDelegate.h"
#import "ItemQuiz.h"



@implementation MissionItem

@synthesize missionID,itemID,mandatory,itemType,latitude,longitude,blackCnt,blackTime,rangeAR,showType,effectiveTime,effectiveRange,itemGame,info,relationItemID;
@synthesize itemQuizzes,rnpSeq,quizSeq;
/*
 -(TreasureHunterAppDelegate *)appDeligate;
 {
 return (TreasureHunterAppDelegate *)[[UIApplication sharedApplication] delegate];
 }
 */
- (id) copyWithZone: (NSZone*) zone
{
	MissionItem *missionItem = [[[self class] allocWithZone:zone] init];
	
	missionItem.missionID = self.missionID;
	missionItem.itemID = self.itemID;
	missionItem.mandatory = self.mandatory;
	missionItem.itemType = self.itemType;
	missionItem.latitude = self.latitude;
	missionItem.longitude = self.longitude;
	missionItem.blackCnt = self.blackCnt;
	missionItem.blackTime = self.blackTime;
	missionItem.rangeAR = self.rangeAR;
	missionItem.showType = self.showType;
	missionItem.effectiveRange = self.effectiveRange;
	missionItem.effectiveTime = self.effectiveTime;
	missionItem.itemGame = self.itemGame;
	missionItem.info = self.info;
	
	int i;
	for(i = 0; i < [itemQuizzes count]; i++)
	{
		ItemQuiz *itemQuizCopy = [[[itemQuizzes objectAtIndex:i] copy] autorelease];
		[missionItem.itemQuizzes insertObject:itemQuizCopy atIndex:i];
	}
	
	return missionItem;
}
-(id)init
{
	self = [super init];
	if (self != nil)
	{
		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat:@"yyyyMMddHHmmss"];
        
		self.mandatory = MANDATORY_N;
		self.rangeAR = 30;
        self.quizSeq = 1;
		self.blackCnt = 5;
		self.blackTime = 300; //5분
        
		itemQuizzes = [[NSMutableArray alloc] init];
	}
	return self;
}



- (void)addItemQuiz
{
	ItemQuiz *itemQuiz = [[[ItemQuiz alloc] init] autorelease];
	itemQuiz.missionID = self.missionID;
	itemQuiz.itemID = self.itemID;
	itemQuiz.seq = self.quizSeq++;
	[self.itemQuizzes addObject:itemQuiz];		
}


-(void)dealloc
{
	self.missionID =nil;
	self.itemType =nil;
	
	self.showType = nil;

	
	self.itemQuizzes = nil;
	self.info = nil;
	
	[super dealloc];
}
@end
