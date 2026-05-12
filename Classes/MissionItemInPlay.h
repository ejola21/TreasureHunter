//
//  MissionItemInPlay.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 4. 9..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MissionItemInPlay : NSObject {
	NSMutableString		*missionID;
	NSMutableString		*playerID;
	int								itemID;
	NSMutableString		*endYN;
	int							  failCnt;
	NSDate				*startTime;    //미션시작시간
	NSDate				*endTime;    //미션시작시간
	int								quizSeq;
}

@property (nonatomic,retain) NSMutableString *missionID;
@property (nonatomic,retain) NSMutableString *playerID;
@property (assign) int itemID;
@property (nonatomic,retain) NSMutableString		*endYN;
@property (assign) int failCnt;
@property (nonatomic,retain) NSDate				*startTime;
@property (nonatomic,retain) NSDate				*endTime;
@property (assign) int quizSeq;

-(id)initWithMissionID:(NSString *)_missionID PlayerID:(NSString *)_playerID ItemID:(int)_itemID;
@end
