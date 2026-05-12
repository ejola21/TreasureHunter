//
//  ItemRnPInPlay.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 5. 7..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "ItemRnPInPlay.h"


@implementation ItemRnPInPlay
@synthesize missionID,playerID,itemType,ableCnt,ableTime,acquiredTime;
-(void)dealloc
{
	self.missionID =nil;
	self.playerID =nil;
    self.itemType = nil;
	self.ableCnt = 0;
	self.ableTime = nil;
	self.acquiredTime =nil;
	
	[super dealloc];
}

@end
