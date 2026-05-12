//
//  Mission.h
//  TreasureHunter
//
//  Created by ejola on 11. 3. 4..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnnoItem;
@class MissionItem;
@class TreasureHunterAppDelegate;


@interface Mission : NSObject<NSCopying> {
	NSMutableString		*mID;
	NSMutableString		*mTitle;				//
	NSMutableString		*mDescription;	//
	NSMutableString		*mPlace;				//
	NSMutableString		*mDesigner;
	NSDate						*mStartTime;    //미션시작시간
	NSDate						*mRunLimitTime;	//미션제한시간
 	NSMutableString   *mQuiz;
	NSMutableString   *mAnswer;
	int								mStatus;  
	NSMutableArray		*mItems;
	NSDate				*mWriteDate;    //수정제작일 
	int                 mVirtual;		//최초제작일		
	int					mSeq;   //아이템 아이디 채번용
	//NSNumber					*mStartEnd; 시작 종료 아이템 존재 여부
	NSString            *mLang;  //사용자 국가
 //달성률 및 금은동 은 플레이 테이블 이용하여 조회
}

@property (nonatomic,retain) NSMutableString *mID;
@property (nonatomic,retain) NSMutableString *mTitle;
@property (nonatomic,retain) NSMutableString *mDescription;
@property (nonatomic,retain) NSMutableString *mPlace;
@property (nonatomic,retain) NSMutableString *mDesigner;
@property (nonatomic,retain) NSDate	*mStartTime;
@property (nonatomic,retain) NSDate	*mRunLimitTime;
@property (nonatomic,retain) NSMutableString *mQuiz;
@property (nonatomic,retain) NSMutableString *mAnswer;
@property (assign) int  mStatus;
@property (assign) int  mSeq;
@property (assign) int  mVirtual;
@property (nonatomic,retain) NSMutableArray *mItems;
@property (nonatomic,retain) NSDate	*mWriteDate;
@property (nonatomic,retain) NSString	*mLang;

//@property (assign) int seq;

-(TreasureHunterAppDelegate *)appDeligate;
-(MissionItem *)addMissionItem;
-(Mission *)getDBMission:(Mission *)mission;
-(int)getDBMaxItemID:(NSMutableString *)missionID;
-(void)getDBBuildMissions;
-(void)getDBALLBuildMissions;
//- (void)addMissionItem;

@end
