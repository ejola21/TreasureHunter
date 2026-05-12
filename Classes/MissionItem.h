//
//  MissionItem.h
//  TreasureHunter
//
//  Created by noh jh on 11. 2. 13..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class TreasureHunterAppDelegate;

// 아이템 코드 

//필수는 40번대 하드코딩

#define	I_QUIZ				@"40"
#define	I_QUIZ20			@"41"
//두번째 섹션 1줄
#define	I_TIMEOUT_S		@"42"
#define	I_TIMEOUT_E		@"43"
#define	I_START				@"49"
#define	I_END					@"48"


//두번째 섹션 3줄
#define I_RADAR_BLACK @"69"  //미추가

//두번째 섹션 2줄
#define	I_NUM00				@"00"
#define	I_NUM01				@"01"
#define	I_NUM02				@"02"
#define	I_NUM03				@"03"
#define	I_NUM04				@"04"
#define	I_NUM05				@"05"
#define	I_NUM06				@"06"
#define	I_NUM07				@"07"
#define	I_NUM08				@"08"
#define	I_NUM09				@"09"
#define	I_ALPHABET		@"10"
#define I_SIMPLE			@"51"
#define I_COUPON			@"59"

//두번째 섹션 1줄
#define	I_RANDOM			@"50"
#define I_SOLUTION		@"52"
//#define	I_GAME				@"53"
#define I_PENALTY_REMOVE @"54"
#define	I_MINE				@"55"
#define I_BLACK       @"56"
#define I_MINE_NOBOMB @"61" 
#define	I_RADAR_AR		@"65"
#define	I_RADAR_MAP		@"66"
#define	I_RADAR_ALL		@"67"
#define I_RADAR_MINE  @"68"

//두번째 섹션 없음
#define	I_STORE				@"91"


//#define	I_HOSPITAL		@"92"

// 표시 구분 
#define	SHOW_TRANSPARENT	@"1"
#define	SHOW_AR						@"2"
#define	SHOW_MAP					@"3"
#define	SHOW_ALL					@"4"



@interface MissionItem : NSObject<NSCopying>
{
    
	NSMutableString		*missionID;
	int								itemID;
	int								mandatory;
	NSMutableString		*itemType;
	CLLocationDegrees latitude;
	CLLocationDegrees longitude;
	int								blackCnt;
	int								blackTime;
	int								rangeAR;
	NSMutableString		*showType;
	int								effectiveRange;
	int                             effectiveTime;
	int								itemGame;
	NSMutableString		*info;
	int								relationItemID;
	
	NSMutableArray *itemQuizzes;
	int							quizSeq;
	int							rnpSeq;
	
}

@property (nonatomic,retain) NSMutableArray *itemQuizzes;
@property (nonatomic,retain) NSMutableString *missionID;
@property (assign) int itemID;
@property (assign) int mandatory;
@property (nonatomic,retain)	NSMutableString	*itemType;
@property (assign) 	CLLocationDegrees latitude;
@property (assign) 	CLLocationDegrees longitude;
@property (assign)	int	blackCnt;
@property (assign)  int	blackTime;
@property (assign) int rangeAR;
@property (nonatomic,retain)	NSMutableString		*showType;
@property (assign) int effectiveRange;
@property (assign) int  effectiveTime;
@property (assign) int 	itemGame;
@property (nonatomic,retain)	NSMutableString		*info;
@property (assign) int relationItemID;
@property (assign) int quizSeq;
@property (assign) int rnpSeq;

- (void)addItemQuiz;

//- (TreasureHunterAppDelegate *) appDeligate;


@end

