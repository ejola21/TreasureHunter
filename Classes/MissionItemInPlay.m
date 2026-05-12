//
//  MissionItemInPlay.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 4. 9..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "MissionItemInPlay.h"


@implementation MissionItemInPlay
@synthesize missionID,playerID,itemID,endYN,failCnt,startTime,endTime,quizSeq;
-(id)initWithMissionID:(NSString *)_missionID PlayerID:(NSString *)_playerID ItemID:(int)_itemID;
{
	self = [super init];
	if (self != nil) {
		self.missionID = (NSMutableString *)_missionID;
		self.playerID = (NSMutableString *)_playerID;
		self.itemID = _itemID;
		self.endYN = (NSMutableString *)@"N";
        self.failCnt = 0;
		self.quizSeq = 0;
	}
	return self;
}

-(void)dealloc
{
	self.missionID =nil;
	self.playerID =nil;
	
	self.endYN = nil;
	self.startTime =nil;
	self.endTime = nil;
	
	[super dealloc];
}

@end
