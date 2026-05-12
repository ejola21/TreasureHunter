//
//  Mission.m
//  TreasureHunter
//
//  Created by ejola on 11. 3. 4..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Mission.h"
#import "TreasureHunterAppDelegate.h"
#import "MissionItem.h"
#import "MissionDao.h"
#import "MissionItemDao.h"

#import "ItemQuizDao.h"



@implementation Mission
@synthesize mID,mTitle,mDescription,mPlace,mDesigner,mStartTime,mRunLimitTime;
@synthesize mStatus,mItems,mWriteDate,mSeq,mQuiz,mAnswer,mVirtual,mLang;



-(TreasureHunterAppDelegate *)appDeligate
{
	return (TreasureHunterAppDelegate *)[[UIApplication sharedApplication] delegate];
}

-(id) copyWithZone: (NSZone*) zone
{
	Mission *mission = [[[self class] allocWithZone:zone] init];
	
	mission.mID = self.mID;
	mission.mTitle = self.mTitle;
	mission.mDescription = self.mDescription;
	mission.mPlace = self.mPlace;
	mission.mDesigner = self.mDesigner;
	mission.mStartTime = self.mStartTime;
	mission.mRunLimitTime = self.mRunLimitTime;
	mission.mStatus = self.mStatus;
	mission.mWriteDate = self.mWriteDate;
	mission.mVirtual = self.mVirtual;
	mission.mQuiz = self.mQuiz;
	mission.mAnswer = self.mAnswer;
    mission.mLang = self.mLang;
	
	mission.mSeq = self.mSeq;
	
	for (int i = 0; i < [mItems count] ; i++)
	{
		MissionItem *missionItemCopy = [[[mItems objectAtIndex:i] copy] autorelease];
		[mission.mItems insertObject:missionItemCopy atIndex:i];
	}
	return mission;
    
}

-(id)init
{
	self = [super init];
	if (self != nil) 
	{
        
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
        NSDateFormatter * dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyMMddhhmmssSSS"];
        
        NSString *tempString = [[[UIDevice currentDevice] uniqueIdentifier] substringToIndex:5]; 
        if([[APPDEL gUserID] length] > 5){
            tempString = [[APPDEL gUserID] substringToIndex:5];
        }
        
		self.mID = [NSString stringWithFormat:@"%@%@",tempString, [dateFormatter stringFromDate:date]];
		self.mStatus = DESIGNING;
        self.mVirtual = VIRTUAL_MODE;
        MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
        self.mSeq = [missionItemDao selecAtMaxItemID:self.mID];
        self.mLang = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
		//self.mSeq = 1;
		mItems = [[NSMutableArray alloc] init];
	}
	return self;
}
- (MissionItem *)addMissionItem
{
	MissionItem *missionItem = [[[MissionItem alloc] init] autorelease];
	missionItem.missionID = self.mID;
	missionItem.itemID = self.mSeq++;
    /*
    MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
    missionItem.itemID = [missionItemDao selecAtMaxMissionID:missionItem.missionID];
	*/
	[self.mItems addObject:missionItem];	
	return missionItem;
}

-(Mission *)getDBMission:(Mission *)mission;
{
	
	//Mission *mission = [[Mission alloc] init];
	
	MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
	ItemQuizDao *itemQuizDao = [[[ItemQuizDao alloc] init] autorelease];
    
	
	MissionItem *missionItem; 
	
	mission.mItems = [missionItemDao selectAt:mission.mID];
	mission.mSeq = [self getDBMaxItemID:mission.mID];
	mission.mSeq--;
    
	for (int j=0; j < [mission.mItems count]; j++)
	{
		missionItem = [mission.mItems objectAtIndex:j];
		
		NSMutableArray *tmp = [itemQuizDao selectAt:mission.mID	ItemID:missionItem.itemID];
		if (tmp != nil) missionItem.itemQuizzes = tmp;
		/*
         missionItem.itemQuizzes = [itemQuizDao selectAt:mission.mID	ItemID:missionItem.itemID];
         missionItem.itemRewards = [itemRnPDao selectRP:mission.mID ItemID:missionItem.itemID RP:@"1"];
         missionItem.itemPenalties = [itemRnPDao selectRP:mission.mID ItemID:missionItem.itemID RP:@"2"];
		 */
	}
	return mission;
}

// DB 에서 itemID 따오기
-(int)getDBMaxItemID:(NSMutableString *)missionID
{
	
	MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
	int ret = [missionItemDao selecAtMaxItemID:missionID];
	
	return ret;
}

// DB 모든 미션 select (테스트용)
-(void)getDBALLBuildMissions {
    
    MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
	NSMutableArray *missions;
	missions = [missionDao selectMissionStatus:SERVER_UPLOAD];
    //[[APPDEL buildingMissions] addObjectsFromArray:[missionDao selectMissionStatus:DESIGNING]];
	
	[[APPDEL buildingMissions] removeAllObjects];
	for (int i=0; i < [missions count]; i++) 
	{
		Mission *mission = [missions objectAtIndex:i];
        mission = [self getDBMission:mission];
		[[APPDEL buildingMissions] addObject:mission];
	}
}


// DB 에서 디자인중인 미션 select
-(void)getDBBuildMissions {
    
    MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
	NSMutableArray *missions;
	missions = [missionDao selectMissionStatus:TESTED];
    //[[APPDEL buildingMissions] addObjectsFromArray:[missionDao selectMissionStatus:DESIGNING]];
	
	[[APPDEL buildingMissions] removeAllObjects];
	for (int i=0; i < [missions count]; i++) 
	{
		Mission *mission = [missions objectAtIndex:i];
        mission = [self getDBMission:mission];
		[[APPDEL buildingMissions] addObject:mission];
	}
	
	
	/*
	 int i;
	 for (i=0; i < [missions count]; i++) 
	 {
	 Mission *mission = [missions objectAtIndex:i];
	 
	 MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
	 ItemQuizDao *itemQuizDao = [[[ItemQuizDao alloc] init] autorelease];
	 ItemRnPDao *itemRnPDao = [[[ItemRnPDao alloc] init] autorelease];
	 
	 MissionItem *missionItem =[[[MissionItem alloc] init] autorelease];
	 
	 mission.mItems = [missionItemDao selectAt:mission.mID];
	 int j;
	 for (j=0; j < [mission.mItems count]; j++)
	 {
	 missionItem = [mission.mItems objectAtIndex:j];
	 missionItem.itemQuizzes = [itemQuizDao selectAt:mission.mID	ItemID:missionItem.itemID];
	 missionItem.itemRewards = [itemRnPDao selectRP:mission.mID ItemID:missionItem.itemID RP:@"1"];
	 missionItem.itemPenalties = [itemRnPDao selectRP:mission.mID ItemID:missionItem.itemID RP:@"2"];
	 }
	 [[APPDEL buildingMissions] addObject:mission];
	 
	 
	 }
	 */
}




-(void)dealloc
{
	
	self.mID =nil;
	self.mDescription = nil;
	self.mPlace =nil;
	self.mDesigner = nil;
	self.mStartTime = nil;
	self.mRunLimitTime = nil;
	self.mQuiz = nil;
	self.mAnswer = nil;
	self.mItems = nil;
	
	
	[super dealloc];
}

@end

