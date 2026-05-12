//
//  MissionPlay.h
//  TreasureHunter
//
//  Created by 시현 이 on 11. 2. 19..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AnnoItem.h"
#import "TreasureHunterAppDelegate.h"
#import "MissionItem.h"
#import "ItemQuiz.h"
#import "MissionInPlay.h"
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import "CMPopTipView.h"
#import "MissionListDetailController.h"
#import "SVProgressHUD.h"
#import <StoreKit/StoreKit.h>

@interface MissionPlay : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate,CMPopTipViewDelegate,UIGestureRecognizerDelegate,SKPaymentTransactionObserver> {
	MKMapView *mapView1;
    
	NSMutableArray *mapAnnotations;
    NSMutableArray *hints;
	NSMutableArray *mapOverlays;
	NSMutableString *missionID;
    
    NSMutableString *missionTitle;
    NSMutableString *missionDesc;
	int isNewStart;
	int missionState;
	NSMutableDictionary *dicItemEnd;    //아이템 획득 여부 Dictionary
	NSMutableDictionary *dicRnPTaken;   //레이더, 지뢰피해 방지등 기능을 써먹을수 있는 현재까지 획득한 아이템
    int isTimeOutS;                     //Run 시작획득 아이템ID
    int isTimeOutE;                     //Run 종료 아이템ID
	BOOL missionStarted;
	BOOL missionCompleted;
    BOOL isVirtualMode;
    BOOL isMissionEnd;
    BOOL onBuy;
    BOOL islimitTime;
	NSDate *missionStartTime;
	NSDate *runLimitTime;
	NSDate *timeOutStartTime;
	int     timeOutLimitTime;
	
	UILabel *mine;
    UILabel *mandatory;
	UILabel *invisibleMap;
	UILabel *invisibleAR;
	
	
	UILabel *dueTimeOut;
	UILabel *passedTimeOut;
	UIView *timeOutView;
	NSString *missionQuiz;
	NSString *missionAnswer;
    NSTimer *passedTimer;
    NSDictionary *missionDic;
    
     MissionListDetailController *missionDetail;
@private
	UIView *playTimeView;
	UIView *statusView;
	UIButton* bCamera;
    BOOL isFirstGps;
    
	UINavigationItem *navigationNewItem;
    NSArray *_clockTickers;
    NSArray *_tclockTickers;
    NSString *passTime;
    NSString *RunPassTime;

}



@property (retain, nonatomic) IBOutlet UINavigationItem *navigationNewItem;
@property (nonatomic, retain) IBOutlet MKMapView *mapView1;
@property (nonatomic, retain) IBOutlet UIView *playTimeView;

@property (nonatomic, retain) NSMutableArray *mapAnnotations;
@property (nonatomic, retain) NSMutableArray *hints;
@property (nonatomic, retain) NSMutableArray *mapOverlays;
@property (nonatomic, retain) NSMutableString		*missionID;
@property (nonatomic, retain) NSMutableString		*missionTitle;
@property (nonatomic, retain) NSMutableString		*missionDesc;
@property (nonatomic, assign) int isNewStart;
@property (nonatomic, assign) int isTimeOutS;
@property (nonatomic, assign) int isTimeOutE;

@property (nonatomic, retain) NSMutableDictionary *dicItemEnd;
@property (nonatomic, retain) NSMutableDictionary *dicRnPTaken;
@property (nonatomic, retain) NSDictionary *missionDic;

@property (nonatomic, assign) BOOL missionStarted;
@property (nonatomic, assign) BOOL missionCompleted;
@property (nonatomic, assign) BOOL isVirtualMode;
@property (nonatomic, assign) BOOL isMissionEnd;

@property (nonatomic, retain) NSDate *missionStartTime;
@property (nonatomic, retain) NSDate *runLimitTime;
@property (nonatomic, retain) NSDate *timeOutStartTime;
@property (assign) int timeOutLimitTime;
@property (nonatomic, retain) NSString *RunPassTime;
@property (nonatomic, retain) NSString *passTime;
@property (nonatomic, retain) NSArray *_tclockTickers;

@property (nonatomic, retain) UILabel *mine;
@property (nonatomic, retain) UILabel *mandatory;
@property (nonatomic, retain) UILabel *invisibleMap;
@property (nonatomic, retain) UILabel *invisibleAR;

@property (nonatomic, retain) UILabel *dueTimeOut;
@property (nonatomic, retain) UILabel *passedTimeOut;

@property (nonatomic, retain) UIView *timeOutView;
@property (nonatomic, retain) NSString *missionQuiz;
@property (nonatomic, retain) NSString *missionAnswer;

@property (nonatomic, retain)	NSArray			*colorSchemes;
@property (nonatomic, retain)	NSDictionary	*contents;
@property (nonatomic, retain)	id				currentPopTipViewTarget;
@property (nonatomic, retain)	NSMutableArray	*visiblePopTipViews;
@property (retain, nonatomic) IBOutlet UINavigationBar *naviBar;
@property (retain, nonatomic) MissionListDetailController *missionDetail;

+ (CGFloat)annotationPadding;
+ (CGFloat)calloutHeight;

- (BOOL)setupPlay;
- (void)virtualMode:(NSMutableArray *)items;
- (void)onCameraView:(id) sender;
- (void)onInfo:(id) sender;
- (void)InfoUpdate;
- (void)updatePlayInfo;
- (void)ExitClick;
- (void)updatePassedTime:(NSTimer *)timer;
- (UIImage *)convertImageBW:(UIImage *)image;
- (UIImage *)convertImageYellow:(UIImage *)originalImage;
- (void)didReceiveFinished:(NSString *)result;
- (BOOL)uploadMissionPlay:(MissionInPlay *)missionInPlay tran:(NSString *)trName;
- (BOOL)mineBlast:(MissionItem *) aItem;
- (void)gotoCurrentLocation;
- (void)finishTimeAlert;
- (void)failAelrt;
- (void)finishAlert;
- (void)blastAlert:(int)kind key:(NSString*)key;

@end
