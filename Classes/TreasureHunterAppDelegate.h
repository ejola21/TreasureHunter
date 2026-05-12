//
//  TreasureHunterAppDelegate.h
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "FMDatabase.h"


@class Mission;

@interface TreasureHunterAppDelegate : NSObject <UIApplicationDelegate,CLLocationManagerDelegate,UITabBarControllerDelegate> {
    UIWindow *window;
	UITabBarController *tabBarController;
	CLLocationManager *locationManager;
	
	NSString *gUserID;
    NSString *guestUserID;
	
	//MissionItem missionItem;
	// 
    //	NSArray *itemType;
    //	NSArray *showType;
	
	//NSUInteger effectiveCount[10];
	FMDatabase *db;
	//NSAutoreleasePool *pool;
	
	NSArray *itemGame;
	NSArray *effectiveRange;
	NSArray *itemNumber;
	NSArray *itemAlphabet;
	NSArray *rangeAR;
	NSArray *blackCnt;
	NSArray *blackTime;
	NSArray *mandatory;
	
	NSArray *rewardKeys;
	NSArray *rewardObjects;	
	NSArray *penaltyKeys;
	NSArray *penaltyObjects;
	NSArray *itemTypeKesys;
	NSArray *itemTypeObjects;
	NSArray *showTypeKeys;
	NSArray *showTypeObjects;
	
    NSArray *itemTypeFiles;
	//NSArray *itmeGameObjects;
	//NSArray *itemGameKeys;
	
	NSDictionary *itemType;
	NSDictionary *showType;
	NSDictionary *reward;
	NSDictionary *penalty;
    CLLocation *startPoint;
    NSMutableDictionary *playedImg;
    NSMutableDictionary *designedImg;
    NSMutableArray *playedArray;
    NSMutableArray *designedArray;
    NSMutableDictionary *playingDic;
	//NSDictionary *itemGame;
	
	
	NSMutableArray *buildingMissions;
    
	Mission *playMission;
	UIColor *backColor; 
    UIColor *cellColor;
    int solutionCount;
    int timeAddCount;
    
    NSMutableDictionary *soundIDDic;
}

@property (nonatomic, retain) NSMutableDictionary *soundIDDic;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *startPoint;
@property (nonatomic,retain) NSString *gUserID;
@property (nonatomic,retain) NSString *guestUserID;
@property (assign) NSUInteger itemSeq;
//@property (assign) MissionItem missionItem;

//@property (nonatomic, retain) NSArray *itemType;
//@property (nonatomic, retain) NSArray *showType;

@property (nonatomic, retain) NSArray *itemGame;
@property (nonatomic, retain) NSArray *effectiveRange;
@property (nonatomic, retain) NSArray *itemNumber;
@property (nonatomic, retain) NSArray *itemAlphabet;
@property (nonatomic, retain) NSArray *rangeAR;
@property (nonatomic, retain) NSArray *blackTime;
@property (nonatomic, retain) NSArray *blackCnt;
@property (nonatomic, retain) NSArray *mandatory;

@property (nonatomic, retain) NSArray *itemTypeKeys;
@property (nonatomic, retain) NSArray *itemTypeObjects;


@property (nonatomic, retain) NSArray *itemTypeFiles;

@property (nonatomic, retain) NSArray *showTypeKeys;
@property (nonatomic, retain) NSArray *showTypeObjects;
//@property (nonatomic, retain) NSArray *itemGameObjects;
//@property (nonatomic, retain) NSArray *itemGameKeys;

@property (nonatomic, retain) NSMutableArray *buildingMissions;
@property (nonatomic, retain) NSMutableArray *playedArray;
@property (nonatomic, retain) NSMutableArray *designedArray;
@property (readonly) NSDictionary *itemType;
@property (readonly) NSDictionary *showType;
@property (nonatomic, retain) NSMutableDictionary *playedImg;
@property (nonatomic, retain) NSMutableDictionary *designedImg;
@property (nonatomic, retain) NSMutableDictionary *playingDic;


//@property (readonly) NSDictionary *itemGame;
@property (nonatomic, retain) FMDatabase *db;
@property (nonatomic, retain) Mission *playMission;
@property (nonatomic, retain) UIColor *backColor; 
@property (nonatomic, retain) UIColor *cellColor; 
@property (nonatomic) int designCount;
@property (nonatomic) int playedCount;
@property (nonatomic,assign) int solutionCount;
@property (nonatomic,assign) int timeAddCount;

-(NSString *)toNSString:(NSDate *)inDate:(NSString *)dFormat;
-(NSDate *)toNSDate:(NSString*)inString:(NSString *)dFormat;
-(NSString *)toGMTNSString:(NSDate *)inDate :(NSString *)dFormat;
-(NSDate *)toGMTNSDate:(NSString *)inString : (NSString *)dFormat;
-(NSString *)sec2timeFormat:(int) seconds;
-(int)timeFormat2sec:(NSString *) timeFormat;

//-(NSUInteger)addItemSeq;
-(void)hideKeyboard;
-(BOOL)initDatabase;

//+(BOOL) isGameCenterAvailable;

- (void)locationManagerInit: (id)sender;
- (NSString *)itemMapFile:(NSMutableString	*)itemType1;
- (NSString *)itemMandatoryMapFile:(NSMutableString	*)itemType1;
- (NSString *)itemAcquiredMapFile:(NSMutableString	*)itemType1;
- (NSString *)itemARFile:(NSMutableString	*)itemType1;
- (NSString *)itemMandatoryARFile:(NSMutableString	*)itemType1;
- (void) checkNAddImg:(NSString*)missionID;
- (void) checkNAddDesignImg:(NSString*)missionID;
- (void) playSystemSound:(NSString*)fileName fileType:(NSString*)type;
- (void)regGUserID:(NSString *)_gUserID;

@end
