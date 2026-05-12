//
//  MissionInPlay.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 4. 9..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MissionInPlay : NSObject {
	NSMutableString		*missionID;
	NSMutableString		*playerID;
	NSMutableString		*startYN;
	NSMutableString		*endYN;
	NSDate				*startTime;    //미션시작시간
	NSDate				*endTime;    //미션시작시간
	
	NSMutableArray		*items;
}

@property (nonatomic,retain) NSMutableString *missionID;
@property (nonatomic,retain) NSMutableString *playerID;
@property (nonatomic,retain) NSMutableString *startYN;
@property (nonatomic,retain) NSMutableString		*endYN;
@property (nonatomic,retain) NSDate				*startTime;
@property (nonatomic,retain) NSDate				*endTime;
@property (nonatomic,retain) NSMutableArray *items;

-(id)initWithMissionID:(NSString *)_missionID  PlayerID:(NSString *)_playerID;
-(id)initAndStart:(NSString *)_missionID PlayerID:(NSString *)_playerID;
@end
