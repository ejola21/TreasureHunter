//
//  MissionInPlay.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 4. 9..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "MissionInPlay.h"


@implementation MissionInPlay
@synthesize missionID,playerID,startYN,endYN,startTime,endTime,items;

-(id)init
{
	self = [super init];
	if (self != nil) {
		self.startYN = (NSMutableString *)@"N";
		self.endYN = (NSMutableString *)@"N";
		items = [[NSMutableArray array] retain];
	}
	return self;
}

-(id)initWithMissionID:(NSString *)_missionID PlayerID:(NSString *)_playerID
{
	self = [super init];
	if (self != nil) {
		self.missionID = (NSMutableString *)_missionID;
		self.playerID = (NSMutableString *)_playerID;
		self.startYN = (NSMutableString *)@"N";
		self.endYN = (NSMutableString *)@"N";
		items = [[NSMutableArray array] retain];
	}
	return self;
}

-(id)initAndStart:(NSString *)_missionID PlayerID:(NSString *)_playerID
{
	self = [super init];
	if (self != nil) {
		self.missionID = (NSMutableString *)_missionID;
		self.playerID = (NSMutableString *)_playerID;
		self.startYN = (NSMutableString *)@"Y";
		self.endYN = (NSMutableString *)@"N";
		self.startTime = [NSDate date];
		items = [[NSMutableArray array] retain];
	}
	return self;
}

-(void)dealloc
{
	self.missionID =nil;
	self.playerID =nil;
	self.startYN = nil;
	self.endYN = nil;
	self.startTime =nil;
	self.endTime = nil;
	self.items = nil;
	[super dealloc];
}

@end
