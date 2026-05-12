//
//  MissionPlay.m
//  TreasureHunter
//
//  Created by 이 인상 on 11. 2. 19..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "MissionPlay.h"
#import "MissionDao.h"
#import "MissionItemDao.h"
#import "ItemQuizDao.h"
#import "MissionInPlay.h"
#import "MissionItemInPlay.h"
#import "MissionInPlayDao.h"
#import "MissionItemInPlayDao.h"
#import "ItemRnPInPlayDao.h"
#import "ItemRnPInPlay.h"
#import "MissionDao.h"
#import "CircleItem.h"
#import "ARGeoViewController.h"
#import "MissionPlayInfo.h"
#import "HTTPRequest.h"
#import "TextAlertView.h"
#import "SBTickerView.h"
#import "SBTickView.h"
#import "MissionInfoAlertView.h"
#import "NoticAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import "SBJson.h"

#define COOKBOOK_PURPLE_COLOR	[UIColor colorWithRed:0.20392f green:0.19607f blue:0.61176f alpha:1.0f]

@implementation MissionPlay
@synthesize navigationNewItem;
@synthesize missionDic;

@synthesize mapView1,mapAnnotations,mapOverlays,playTimeView,hints;
@synthesize missionID,missionTitle,missionDesc;
@synthesize isNewStart,isTimeOutS,isTimeOutE,isVirtualMode,isMissionEnd;

@synthesize dicItemEnd,dicRnPTaken,RunPassTime,passTime;
@synthesize missionStarted;
@synthesize missionCompleted;
@synthesize missionStartTime;
@synthesize runLimitTime;
@synthesize timeOutStartTime;
@synthesize timeOutLimitTime,_tclockTickers;

@synthesize mine;
@synthesize mandatory;
@synthesize invisibleMap;
@synthesize invisibleAR;


@synthesize dueTimeOut;
@synthesize passedTimeOut;
@synthesize timeOutView;
@synthesize missionQuiz;
@synthesize missionAnswer;

@synthesize colorSchemes;
@synthesize contents=_contents;
@synthesize currentPopTipViewTarget;
@synthesize visiblePopTipViews;
@synthesize naviBar;
@synthesize missionDetail;

#pragma mark -
#pragma mark Life Cycle Functions
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.wantsFullScreenLayout = NO;
    [statusView removeFromSuperview];
    [timeOutView removeFromSuperview];
    [playTimeView removeFromSuperview];
    [bCamera removeFromSuperview];
    
    mapAnnotations = [[NSMutableArray alloc] init];
    mapOverlays = [[NSMutableArray alloc] init];
    hints = [[NSMutableArray alloc] init];
    missionStarted = NO;
    missionCompleted = NO;
    passedTimer = nil;
    missionStartTime = nil;	
    runLimitTime = nil;	
    islimitTime = YES;
    isFirstGps = YES;
    
    onBuy = false;
    //변수 로딩
    self.missionID = [[APPDEL playingDic] objectForKey:@"missionID"];
    self.missionDic =[[APPDEL playingDic] objectForKey:@"missionDic"];
    self.isNewStart = [[[APPDEL playingDic] objectForKey:@"isNewStart"] intValue];
    self.isVirtualMode = [[[APPDEL playingDic] objectForKey:@"isVirtualMode"] boolValue];
    
	
	[[self navigationController] setNavigationBarHidden:TRUE animated:NO];
    [self.naviBar setTintColor:[APPDEL backColor]];
    
    [APPDEL locationManager].delegate = self;
    [APPDEL locationManager].distanceFilter = kCLDistanceFilterNone;
	[APPDEL locationManager].desiredAccuracy = kCLLocationAccuracyBest; //10m
	[[APPDEL locationManager] startUpdatingLocation];
    [[APPDEL locationManager] startUpdatingHeading];
    
    mapView1 = [[MKMapView alloc] initWithFrame:CGRectMake(0, 44, 320, 460-83)];
    [self.view addSubview:mapView1];
	self.mapView1.delegate = self;
	self.mapView1.tag = 1;
    self.mapView1.showsUserLocation = TRUE;
    self.mapView1.zoomEnabled = YES;
    self.mapView1.scrollEnabled =YES;

    
    UITapGestureRecognizer *recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTouch:)] autorelease];
	recognizer.delegate = self;
    [mapView1 addGestureRecognizer:recognizer];
    
    isMissionEnd =  FALSE;
    
    
    
	if([self setupPlay] == NO) {
		return;
	}
	
    
	//////////////////////////////////////////////////////////////////////////////////
	// 툴바 버튼 set
	
	// create a toolbar to have two buttons in the right
	UIToolbar* tools = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 80, 44.01)];
	
	// create the array to hold the buttons, which then gets added to the toolbar
	NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:1];
    [tools setTintColor:[APPDEL backColor]];
	
	// 현위치
	UIImage *buttonImage = [UIImage imageNamed:@"button_now.png"];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:buttonImage forState:UIControlStateNormal];
	button.frame = CGRectMake(0, 0, 30, 30);
    [button addTarget:self action:@selector(gotoCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *pos = [[UIBarButtonItem alloc] initWithCustomView:button];
	[buttons addObject:pos];
	[pos release];
    
    // missionplayinfo
    
    UIImage *btnInfoImage = [UIImage imageNamed:@"button_info.png"];
	UIButton *binfo = [UIButton buttonWithType:UIButtonTypeCustom];
	[binfo setImage:btnInfoImage forState:UIControlStateNormal];
	binfo.frame = CGRectMake(0, 0, 30, 30);
    
	//UIButton* binfo = [UIButton buttonWithType:UIButtonTypeInfoLight];
    
    [binfo addTarget:self action:@selector(onInfo:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *info = [[UIBarButtonItem alloc] initWithCustomView:binfo];
   	[buttons addObject:info];
	[info release];
    
	[tools setItems:buttons animated:NO];
	[buttons release];
	self.navigationNewItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:tools] autorelease];
	[tools release];
    
	
    //left 
	UIBarButtonItem *pBtnDone = [[UIBarButtonItem alloc]initWithTitle:@"Exit" style:UIBarButtonItemStyleBordered
                                                               target:self
                                                               action:@selector(ExitClick)];
	
	[self.navigationNewItem setLeftBarButtonItem:pBtnDone animated:YES];
	[pBtnDone release];
	
    //미션 시간 
    
    SBTickerView *tickHour1 = [[[SBTickerView alloc] initWithFrame:CGRectMake(0, 0, 25, 30)] autorelease];
    SBTickerView *tickHour2 = [[[SBTickerView alloc] initWithFrame:CGRectMake(24, 0, 25, 30)] autorelease];
    SBTickerView *tickMin1 = [[[SBTickerView alloc] initWithFrame:CGRectMake(51, 0, 25, 30)] autorelease];
    SBTickerView *tickMin2 = [[[SBTickerView alloc] initWithFrame:CGRectMake(75, 0, 25, 30)] autorelease];
    SBTickerView *tickSec1 = [[[SBTickerView alloc] initWithFrame:CGRectMake(103, 0, 25, 30)] autorelease];
    SBTickerView *tickSec2 = [[[SBTickerView alloc] initWithFrame:CGRectMake(127, 0, 25, 30)] autorelease];
    
    
    playTimeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    
    [playTimeView addSubview:tickHour1];
    [playTimeView addSubview:tickHour2];
    [playTimeView addSubview:tickMin1];
    [playTimeView addSubview:tickMin2];
    [playTimeView addSubview:tickSec1];
    [playTimeView addSubview:tickSec2];
    
    [[APPDEL window] addSubview:playTimeView];
    
	[playTimeView setFrame:CGRectMake(80,27,150,30)];
    
    _clockTickers = [[NSArray arrayWithObjects:
                      tickHour1,
                      tickHour2,
                      tickMin1,
                      tickMin2,
                      tickSec1,
                      tickSec2, nil] retain];
    
    if (runLimitTime == nil)
        self.passTime = @"000000";
    else {
        self.passTime = [APPDEL toNSString:runLimitTime :@"HHmmss"];
    }
    
    
    for (int i =0; i < [_clockTickers count]; i++) {
        SBTickerView *tickView = [_clockTickers objectAtIndex:i];
        [tickView setFrontView:[SBTickView tickViewWithTitle:[passTime substringWithRange:NSMakeRange(i, 1)] fontSize:24. backColor:RGBA(30, 30, 30, 1)]];
    }
    
    //타임 아웃 시간
    
    // UIImage *imgClock = [UIImage imageNamed:@"clock.png"];
    //UIImageView *imgViewClock = [[[UIImageView alloc] initWithImage:imgClock] autorelease];
    //[imgViewClock setFrame:CGRectMake(0, 0, 35, 35)];
    
    SBTickerView *ttickHour1 = [[[SBTickerView alloc] initWithFrame:CGRectMake(0+40, 0, 25, 30)] autorelease];
    SBTickerView *ttickHour2 = [[[SBTickerView alloc] initWithFrame:CGRectMake(24+40, 0, 25, 30)] autorelease];
    SBTickerView *ttickMin1 = [[[SBTickerView alloc] initWithFrame:CGRectMake(51+40, 0, 25, 30)] autorelease];
    SBTickerView *ttickMin2 = [[[SBTickerView alloc] initWithFrame:CGRectMake(75+40, 0, 25, 30)] autorelease];
    SBTickerView *ttickSec1 = [[[SBTickerView alloc] initWithFrame:CGRectMake(103+40, 0, 25, 30)] autorelease];
    SBTickerView *ttickSec2 = [[[SBTickerView alloc] initWithFrame:CGRectMake(127+40, 0, 25, 30)] autorelease];
    
    //[ttickHour1 setBackgroundColor:[UIColor colorWithRed:0.173 green:0 blue:0 alpha:1.000]];
    //[ttickHour2 setBackgroundColor:[UIColor colorWithRed:0.173 green:0 blue:0 alpha:1.000]];
    
    timeOutView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
    
    //[timeOutView addSubview:imgViewClock];
    [timeOutView addSubview:ttickHour1];
    [timeOutView addSubview:ttickHour2];
    [timeOutView addSubview:ttickMin1];
    [timeOutView addSubview:ttickMin2];
    [timeOutView addSubview:ttickSec1];
    [timeOutView addSubview:ttickSec2];
    
    
    [[APPDEL window] addSubview:timeOutView];
    
	[timeOutView setFrame:CGRectMake(80-40,27,180,30)];
    
    _tclockTickers = [[NSArray arrayWithObjects:
                       ttickHour1,
                       ttickHour2,
                       ttickMin1,
                       ttickMin2,
                       ttickSec1,
                       ttickSec2, nil] retain];
    
    RunPassTime = [[NSString alloc] init];
    [timeOutView setHidden:YES];
    
    /*
     self.RunPassTime = @"00000";
     
     
     for (SBTickerView *ticker in _tclockTickers)
     [ticker setFrontView:[SBTickView tickViewWithTitle:@"0" fontSize:24.]];  
     
     */
    
    
	statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 418, 320, 55)];
	//[statusView sizeToFit];
	UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
	title.font = [UIFont boldSystemFontOfSize:14];
	title.textColor = [UIColor whiteColor];
	title.backgroundColor = COOKBOOK_PURPLE_COLOR;
	title.text = NSLocalizedString(@"mission_play_0", nil);
	
	UILabel *title2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 320, 22)];
	title2.backgroundColor = COOKBOOK_PURPLE_COLOR;
	
    
    mine = [[UILabel alloc] initWithFrame:CGRectMake(15, 22, 30, 22)];
	mine.font = [UIFont boldSystemFontOfSize:14];
	mine.textColor = [UIColor whiteColor];
	mine.backgroundColor = COOKBOOK_PURPLE_COLOR;
	mine.text =@"000";
    
	mandatory = [[UILabel alloc] initWithFrame:CGRectMake(82, 22, 30, 22)];
	mandatory.font = [UIFont boldSystemFontOfSize:14];
	mandatory.textColor = [UIColor colorWithRed:255/255.0 green:117/255.0 blue:221/255 alpha:1.0f];
    
    
	mandatory.backgroundColor = COOKBOOK_PURPLE_COLOR;
	mandatory.text =@"000";
	
	invisibleMap = [[UILabel alloc] initWithFrame:CGRectMake(222, 22, 30, 22)];
	invisibleMap.font = [UIFont boldSystemFontOfSize:14];
    
	invisibleMap.textColor = [UIColor whiteColor];
	invisibleMap.backgroundColor = COOKBOOK_PURPLE_COLOR;
	invisibleMap.text =@"000";
	
	invisibleAR = [[UILabel alloc] initWithFrame:CGRectMake(285, 22, 30, 22)];
	invisibleAR.font = [UIFont boldSystemFontOfSize:14];
	invisibleAR.textColor = [UIColor whiteColor];
	invisibleAR.backgroundColor = COOKBOOK_PURPLE_COLOR;
	invisibleAR.text =@"000";
	
	[statusView addSubview:title];
	[statusView addSubview:title2];
	//[statusView addSubview:binfo];
    
    [statusView addSubview:mine];
	[statusView addSubview:mandatory];
	[statusView addSubview:invisibleMap];
	[statusView addSubview:invisibleAR];
    
       
    [self.view addSubview:statusView];
    
    
	//[statusView setFrame:CGRectMake(0,430,320,50)];
    [title release];
    [title2 release];
	
	// 카메라
	UIImage *imgCamera = [UIImage imageNamed:@"playAR_button.png"];
	bCamera = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	bCamera.frame = CGRectMake(128, 400, 60, 60);
	[bCamera setBackgroundImage:imgCamera forState:UIControlStateNormal];
	//[bCamera setTitle:@"AR" forState:UIControlStateNormal];
	[bCamera addTarget:self action:@selector(onCameraView:) forControlEvents:UIControlEventTouchUpInside];
	
    [self.view addSubview:bCamera];
	
    [self InfoUpdate];
	
    //팁 버튼
    UIButton *btnMine  = [[[UIButton alloc] initWithFrame:CGRectMake(15, 0, 30, 50)] autorelease];
    btnMine.backgroundColor = [UIColor clearColor];
    btnMine.tag = 11;
    [btnMine addTarget:self action:@selector(tip:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnMandatory = [[[UIButton alloc] initWithFrame:CGRectMake(82, 0, 30, 50)] autorelease];
    btnMandatory.backgroundColor = [UIColor clearColor];
    btnMandatory.tag = 12;
    [btnMandatory addTarget:self action:@selector(tip:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnMap = [[[UIButton alloc] initWithFrame:CGRectMake(222, 0, 30, 50)] autorelease];
    btnMap.backgroundColor = [UIColor clearColor];
    btnMap.tag = 13;
    [btnMap addTarget:self action:@selector(tip:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnAR = [[[UIButton alloc] initWithFrame:CGRectMake(285, 0, 30, 50)] autorelease];
    btnAR.backgroundColor = [UIColor clearColor];
    btnAR.tag = 14;
    [btnAR addTarget:self action:@selector(tip:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [statusView addSubview:btnMine];
    [statusView addSubview:btnMandatory];
    [statusView addSubview:btnMap];
    [statusView addSubview:btnAR];
    
    self.visiblePopTipViews = [NSMutableArray array];
	
	self.contents = [NSDictionary dictionaryWithObjectsAndKeys:
					 // Rounded rect buttons
                     
					 NSLocalizedString(@"mission_play_tip_1", nil), [NSNumber numberWithInt:11],
					 NSLocalizedString(@"mission_play_tip_2", nil), [NSNumber numberWithInt:12],
					 NSLocalizedString(@"mission_play_tip_3", nil), [NSNumber numberWithInt:13],
					 NSLocalizedString(@"mission_play_tip_4", nil), [NSNumber numberWithInt:14],
					 [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ar_genius.png"]] autorelease], [NSNumber numberWithInt:16],	// content can be a UIView
                     nil];
	
	// Array of (backgroundColor, textColor) pairs.
	// NSNull for either means leave as default.
	// A color scheme will be picked randomly per CMPopTipView.
	self.colorSchemes = [NSArray arrayWithObjects:
						 [NSArray arrayWithObjects:[NSNull null], [NSNull null], nil],
						 [NSArray arrayWithObjects:[UIColor colorWithRed:134.0/255.0 green:74.0/255.0 blue:110.0/255.0 alpha:1.0], [NSNull null], nil],
						 [NSArray arrayWithObjects:[UIColor darkGrayColor], [NSNull null], nil],
						 [NSArray arrayWithObjects:[UIColor lightGrayColor], [UIColor darkTextColor], nil],
						 [NSArray arrayWithObjects:[UIColor orangeColor], [UIColor blueColor], nil],
						 [NSArray arrayWithObjects:[UIColor colorWithRed:220.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0], [NSNull null], nil],
						 nil];
    if ([SKPaymentQueue canMakePayments]) {	
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];	// Observer를 등록한다.
    }
    
    if (passedTimer == nil) {
        [passedTimer invalidate];
       // passedTimer = nil;
        passedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(updatePassedTime:)
                                                     userInfo:nil
                                                      repeats:YES];
        NSLog(@"MissionPlay viewDidLoad passedTimer set !!!");

    }
    
	
    [APPDEL tabBarController].tabBar.hidden = TRUE;
   
    NSLog(@"MissionPlay viewDidLoad !!!");
}



- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"MissionPlay viewWillAppear start!!!");
	[super viewWillAppear:animated];
    /*
    [APPDEL tabBarController].tabBar.hidden = TRUE;
    if (isMissionEnd) {
        [self finishAlert];
        isMissionEnd = FALSE;
    }
     */
    NSLog(@"MissionPlay viewWillAppear end!!!");
}   

-(void) viewDidAppear:(BOOL)animated {
	
     NSLog(@"MissionPlay viewdidAppear start !!!");
   
    [APPDEL locationManager].delegate = self;
    [self dismissAllPopTipViews];
   
	[statusView setHidden:NO];
	[bCamera setHidden:NO];
    
	if(self.timeOutStartTime != nil) {
		[timeOutView setHidden:NO];
	}
	else {
		[timeOutView setHidden:YES];
	}
    
    if (isMissionEnd) {
        [self finishAlert];
        isMissionEnd = FALSE;
    }
    
	[super viewDidAppear:animated]; 
    
    //[self.mapView1 setNeedsDisplay];
    
    [self.mapView1 removeAnnotations:mapView1.annotations];
	[self.mapView1 addAnnotations:mapAnnotations];
	[self.mapView1 removeOverlays:mapView1.overlays];
	[self.mapView1 addOverlays:mapOverlays];
    
    NSLog(@"MissionPlay viewdidAppear end !!!");
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}


- (void)viewDidUnload {
     NSLog(@"MissionPlay viewDidUnload !!!");
    [self setNaviBar:nil];
    
    [statusView removeFromSuperview];
    [bCamera removeFromSuperview];

    /* 이거 풀면 AR에서 메모리 워닝시 레이더 작동 안함
    [APPDEL locationManager].delegate = nil;
    [[APPDEL locationManager] stopUpdatingLocation];
    [[APPDEL locationManager] stopUpdatingHeading];
     
     //이거 풀면 AR에서 메모리 워닝시 획득아이템 다 날아감
    self.dicItemEnd =nil;
    self.dicRnPTaken =nil;
     //이거 풀면 AR에서 메모리 워닝후 종료시 윈도우에 남아 있음
    self.playTimeView =nil;
     
     */
    
    [passedTimer invalidate];
    passedTimer = nil;
    
    
 
    self._tclockTickers =nil;
    [_clockTickers release]; _clockTickers =nil;
    
	self.mapAnnotations = nil;
	self.mapOverlays  =nil;
    self.missionID =nil;
    self.missionTitle = nil;
    self.missionDesc = nil;
    self.mapView1 =nil;
    
    self.missionStartTime =nil;
    self.runLimitTime =nil;
    
    self.timeOutStartTime =nil;
    
    self.mandatory =nil;
    self.invisibleAR =nil;
    self.invisibleMap =nil;
    
	self.dueTimeOut=nil;
    self.passedTimeOut=nil;
    self.timeOutView =nil;
    self.navigationNewItem = nil;
    
    
    self.contents=nil;
    self.colorSchemes=nil;
    self.currentPopTipViewTarget=nil;
    self.visiblePopTipViews=nil;
    self.hints =nil;
    self.passTime =nil;
    self.RunPassTime = nil;
   	[statusView release];   statusView =nil;
	
    
	[bCamera release];  bCamera=nil;
	[missionQuiz release];      missionQuiz = nil;
	[missionAnswer release]; missionAnswer =nil;
    
    [super viewDidUnload]; 
    
}


- (void)dealloc {
    
    
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!! MissionPlay  dealloc !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    
    [APPDEL locationManager].delegate = nil;
    [[APPDEL locationManager] stopUpdatingLocation];
    [[APPDEL locationManager] stopUpdatingHeading];
	[mapAnnotations release];
	[mapOverlays release];
    [missionID release];
    [missionTitle release];
    [missionDesc release];
	[dicItemEnd release];
	[dicRnPTaken release];
	[mapView1 release];
	
	[missionStartTime release];
	[runLimitTime release];
	[timeOutStartTime release];
    
	
	[mandatory release];
	[invisibleMap release];
	[invisibleAR release];
    
	[dueTimeOut release];
	[passedTimeOut release];
    
	[statusView release];
	[timeOutView release];
	//[bCamera release];
	[missionQuiz release];
	[missionAnswer release];
	
    [passTime release];
    [_clockTickers release];  _clockTickers = nil;
    
    [_contents release];
	[colorSchemes release];
	[currentPopTipViewTarget release];
	[visiblePopTipViews release];
    [hints release];
    [RunPassTime release];

    
    self.navigationNewItem = nil;
    self._tclockTickers = nil;
    self.playTimeView = nil;    
    [naviBar release];
    
    if (passedTimer) {
        [passedTimer invalidate];
        passedTimer = nil;
    }
   
    [super dealloc];
}

#pragma mark -
#pragma mark Time Functions
/*
 - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  
 { 
 if (buttonIndex == 1) {
 
 [statusView removeFromSuperview];
 [timeOutView removeFromSuperview];
 [playTimeView removeFromSuperview];
 [bCamera removeFromSuperview];
 [self.navigationController popViewControllerAnimated:YES];
 if(passedTimer != nil){
 [passedTimer invalidate];
 passedTimer = nil;
 }
 [APPDEL locationManager].delegate = nil;
 [[APPDEL locationManager] stopUpdatingLocation];
 [[APPDEL locationManager] stopUpdatingHeading];
 }
 
 }
 */
-(void)ExitClick 
{
    NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"mission_play_exit_title", nil) 
                                                              message:NSLocalizedString(@"mission_play_exit_message", nil)
                                                               cancel:NSLocalizedString(@"cancel", nil)                                                                    
                                                                   ok:NSLocalizedString(@"ok", nil)
                                                             itemType:nil];
    [alertView setTag:100];
    [alertView setDelegate:self];
    [alertView show];
    [alertView release]; 
    
  	
}

- (void)updatePassedTime:(NSTimer *)timer;
{
	if(missionStartTime == nil)
	{
	}
	else 
    {
	    if(self.missionCompleted == NO)
		{
            
            NSTimeInterval passedInterval = [[NSDate date] timeIntervalSinceDate:missionStartTime];
            
            NSDate *zeroDate = [APPDEL toNSDate:@"2000-01-01 00:00:00" :@"yyyy-MM-dd 00:00:00"];
            NSDate *passedDate = [NSDate dateWithTimeInterval:passedInterval sinceDate:zeroDate];
            NSString *procTime; //= [[[NSString alloc] init] autorelease];
            
            if(self.runLimitTime == nil) 
            {
                procTime = [APPDEL toNSString:passedDate :@"HHmmss"];
                
                [_clockTickers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    if (![[passTime substringWithRange:NSMakeRange(idx, 1)] isEqualToString:[procTime substringWithRange:NSMakeRange(idx, 1)]]) {
                        [obj setBackView:[SBTickView tickViewWithTitle:[procTime substringWithRange:NSMakeRange(idx, 1)] fontSize:24. backColor:RGBA(30, 30, 30, 1)]];
                        [obj tick:SBTickerViewTickDirectionDown animated:YES completion:nil];
                    }
                }];
                self.passTime = procTime;
                
            }
            else
            {
                NSDate *limitTime = [NSDate dateWithTimeInterval:-passedInterval sinceDate:self.runLimitTime];
                procTime = [APPDEL toNSString:limitTime :@"HHmmss"]; 
                
                //NSDate 시간계산이 안되서 변환해서 함
                int passed = [[APPDEL toNSString:passedDate :@"HHmmss"] intValue];
                int limit   = [[APPDEL toNSString:self.runLimitTime :@"HHmmss"] intValue];
                
                if (passed >= limit)
                {   
                    
                    //ARGeoViewController 죽이기
                    UIViewController *viewController = [self.navigationController.viewControllers objectAtIndex:([self.navigationController.viewControllers count]-1)];
                    
                    if ([viewController isMemberOfClass:[ ARGeoViewController class]]) {
                        
                        [(ARGeoViewController *)viewController onMapView:nil];
                    }
                    
                    [self finishTimeAlert];
                    if (passedTimer != nil) {
                        [passedTimer invalidate];
                        passedTimer = nil;
                        
                    }
                    
                    return;
                }
                else if (limit - passed <= 100)
                {
                    
                    [APPDEL playSystemSound:@"s_timer"  fileType:@"mp3"]; 
                    
                    if (islimitTime)
                        for (int i =0; i < [_clockTickers count]; i++) {
                            SBTickerView *tickView = [_clockTickers objectAtIndex:i];
                            [tickView setFrontView:[SBTickView tickViewWithTitle:[passTime substringWithRange:NSMakeRange(i, 1)] fontSize:24. backColor:RGBA(255, 000, 051,1)]];
                            islimitTime = NO;
                        }
                
                    [_clockTickers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        
                        if (![[passTime substringWithRange:NSMakeRange(idx, 1)] isEqualToString:[procTime substringWithRange:NSMakeRange(idx, 1)]]) {
                            [obj setBackView:[SBTickView tickViewWithTitle:[procTime substringWithRange:NSMakeRange(idx, 1)] fontSize:24. backColor:RGBA(255, 000, 051,1)]];
                            [obj tick:SBTickerViewTickDirectionDown animated:YES completion:nil];
                        }
                    }];
                }
                else {
                    [_clockTickers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        
                        if (![[passTime substringWithRange:NSMakeRange(idx, 1)] isEqualToString:[procTime substringWithRange:NSMakeRange(idx, 1)]]) {
                            [obj setBackView:[SBTickView tickViewWithTitle:[procTime substringWithRange:NSMakeRange(idx, 1)] fontSize:24. backColor:RGBA(30, 30, 30, 1)]];
                            [obj tick:SBTickerViewTickDirectionDown animated:YES completion:nil];
                        }
                    }];
                }
                self.passTime = procTime;
             
            }
            
            
		}
		
	}
	
	if(isTimeOutS > 0)
    {
        [APPDEL playSystemSound:@"s_timer"  fileType:@"mp3"]; 
        
        NSDate *curDate = [NSDate date];
        NSTimeInterval interval = [curDate timeIntervalSinceDate:self.timeOutStartTime];
        
        NSUInteger seconds = (NSUInteger)round(timeOutLimitTime - interval);
        NSString *rTime = [[NSString stringWithFormat:@"%02u%02u%02u", seconds / 3600, (seconds / 60) % 60, seconds % 60] retain];
        
        [_tclockTickers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if (![[RunPassTime substringWithRange:NSMakeRange(idx, 1)] isEqualToString:[rTime substringWithRange:NSMakeRange(idx, 1)]]) {
                [obj setBackView:[SBTickView tickViewWithTitle:[rTime substringWithRange:NSMakeRange(idx, 1)] fontSize:24. backColor:RGBA(255, 000, 051, 1)]];
                [obj tick:SBTickerViewTickDirectionDown animated:YES completion:nil];
            }
        }];
        
        self.RunPassTime = rTime;
        
        [rTime release];
        
		if(self.timeOutLimitTime < interval) {
            
            
            self.isTimeOutS = 0;
            self.isTimeOutE = 0;
            self.timeOutStartTime = nil;
            
            [timeOutView setHidden:YES];	
            [playTimeView setHidden:NO];
            
            
            //[mapView1 removeAnnotation:[mapView1.annotations objectAtIndex:0]];
            
            [mapView1 removeAnnotations:mapView1.annotations];
            [mapView1 addAnnotations:mapAnnotations];
            [mapView1 removeOverlays:mapView1.overlays];
            [mapView1 addOverlays:mapOverlays];
            
            [self finishRunTimeAlert];
            
		}
	}
}


- (BOOL)setupPlay
{
    /*
	[self.mapView1 removeAnnotations:self.mapAnnotations];
	[self.mapAnnotations removeAllObjects];
	[self.mapView1 removeOverlays:self.mapOverlays];
	[self.mapOverlays removeAllObjects];
	*/
	MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
	MissionItemDao *itemDao = [[[MissionItemDao alloc] init] autorelease];
    
	Mission *mission = [missionDao selectWithPK:self.missionID];
	self.missionQuiz = mission.mQuiz;
	self.missionAnswer = mission.mAnswer;
	self.runLimitTime = mission.mRunLimitTime;
    self.missionTitle = mission.mTitle;
    self.missionDesc = mission.mDescription;
    missionState = mission.mStatus;
	
	NSMutableArray *items = [itemDao selectAt:self.missionID];
	for (MissionItem *item in items)
	{
        if( [item.itemType isEqualToString:I_QUIZ])
        {     
            ItemQuizDao *quizDao = [[[ItemQuizDao alloc] init] autorelease];
            NSMutableArray *quizzes = [quizDao selectAt:self.missionID ItemID:item.itemID];
            item.itemQuizzes = quizzes;
        }
    }
    
    
	MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc] init] autorelease];
	MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
	ItemRnPInPlayDao *itemRnPInPlayDao = [[[ItemRnPInPlayDao alloc] init] autorelease];
	
	if(isNewStart == 1) {
		[missionInPlayDao deleteAt:self.missionID playerID:[APPDEL gUserID]];
		[missionItemInPlayDao deleteAt:self.missionID playerID:[APPDEL gUserID]];
		[itemRnPInPlayDao deleteAt:self.missionID playerID:[APPDEL gUserID]];
        //isNewStart = 0;
	}
	
	MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:self.missionID playerID:[APPDEL gUserID]];
	
	if(missionInPlay == nil) { // 처음이면
		missionInPlay = [[[MissionInPlay alloc] initWithMissionID:self.missionID 
                                                         PlayerID:[APPDEL gUserID]] autorelease];
		BOOL b = [itemDao startItemExists:self.missionID];
		if (b == NO) { // 시작아이템이 없으면 자동시작
			missionInPlay.startYN = (NSMutableString *)@"Y";
			missionInPlay.startTime = [NSDate date];
			[missionInPlayDao insert:missionInPlay];
			self.missionStarted = YES;
            [self uploadMissionPlay:missionInPlay tran:@"c_mission_play_start"];
			self.missionStartTime = missionInPlay.startTime;
		}
		else { // 시작아이템이 있으면 아직 시작아님
			[missionInPlayDao insert:missionInPlay];
		}		
		
		for (MissionItem *item in items) {
			MissionItemInPlay *missionItemInPlay = [[[MissionItemInPlay alloc] initWithMissionID:self.missionID 
                                                                                        PlayerID:[APPDEL gUserID] ItemID:item.itemID] autorelease];
			[missionItemInPlayDao insert:missionItemInPlay];
		}								 
		
	} else { // 이어서 하던 게임이면
		self.missionStarted = [missionInPlayDao missionStarted:self.missionID playerID:[APPDEL gUserID]];
		self.missionStartTime = missionInPlay.startTime;
	}
    
	self.dicItemEnd = [missionItemInPlayDao selectDicAt:self.missionID playerID:[APPDEL gUserID]];
    
	self.dicRnPTaken = [itemRnPInPlayDao selectDicAt:self.missionID playerID:[APPDEL gUserID]];
    
    self.isTimeOutS = 0;
    self.isTimeOutE = 0;
    
    
	MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao selectLastStartedTimeOut:self.missionID playerID:[APPDEL gUserID]];
	if(missionItemInPlay != nil)
	{
		self.timeOutStartTime = missionItemInPlay.endTime;
		for (MissionItem *item in items)
		{
			if([item.itemType isEqualToString:I_TIMEOUT_E] &&
               item.relationItemID == missionItemInPlay.itemID)
			{
				//NSDate *zeroDate = [APPDEL toNSDate:@"0000":@"mmss"];
				//NSTimeInterval dueInterval = [item.effectiveTime timeIntervalSinceDate:zeroDate];
				//self.timeOutEnd = [NSDate dateWithTimeInterval:dueInterval sinceDate:self.timeOutStart];
				self.timeOutLimitTime = item.effectiveTime;
				break;
			}
		}
	}
	else {
		self.timeOutStartTime = nil;
        
	}
    
	if (isVirtualMode) [self virtualMode:items];
    
    for (MissionItem * item in items) {
        
        AnnoItem *_annoItem = [[AnnoItem alloc] init];
		_annoItem.missionItem = item;
		
		[self.mapAnnotations addObject:_annoItem];
		[self.mapView1 addAnnotation:_annoItem];
		[_annoItem release];
		
		if([item.itemType isEqualToString:I_MINE] || [item.itemType isEqualToString:I_BLACK])
		{
			CLLocationCoordinate2D  cood;
			cood.latitude = item.latitude;
			cood.longitude = item.longitude;
			CircleItem *circle = (CircleItem *)[CircleItem circleWithCenterCoordinate:cood radius:item.rangeAR];
			circle.missionItem = item;
			[self.mapOverlays addObject:circle];
			[self.mapView1 addOverlay:circle];
		}
        else if( [item.itemType isEqualToString:I_START])
        {
            CLLocationCoordinate2D coordinate;
            
            if (isVirtualMode)
                coordinate  = [APPDEL startPoint].coordinate;
            else
            {
                coordinate.latitude = item.latitude;
                coordinate.longitude = item.longitude;
            }
            
            self.mapView1.region = MKCoordinateRegionMakeWithDistance(coordinate, 150, 150);   
        }

    }
    
	return YES;
}	
- (void)virtualMode :(NSMutableArray *)items
{
    double diffLongi;
    double diffLati;
    
    for (MissionItem * item in items) {
        
        
        if (isNewStart == 1) {
            if( [item.itemType isEqualToString:I_START])
            {
                diffLati = [APPDEL startPoint].coordinate.latitude - item.latitude;
                diffLongi = [APPDEL startPoint].coordinate.longitude - item.longitude;
                self.mapView1.region = MKCoordinateRegionMakeWithDistance([APPDEL startPoint].coordinate, 150, 150);            
                break;
            }
            
        }
        else {
            MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
            MissionItem *lastItem = [missionItemInPlayDao 
                                     loadLastAcquiredItem:self.missionID
                                     playerID:[APPDEL gUserID]];
            
            
            if(lastItem != nil) 
            {
                diffLati = [APPDEL startPoint].coordinate.latitude - lastItem.latitude;
                diffLongi = [APPDEL startPoint].coordinate.longitude - lastItem.longitude;
                self.mapView1.region = MKCoordinateRegionMakeWithDistance([APPDEL startPoint].coordinate, 150, 150);            
                break;
            }

        }
    }
    
    for (MissionItem * item in items) {
        item.longitude += diffLongi;
        item.latitude +=  diffLati;
    }
    
}

#pragma mark -
#pragma mark CMPopTipViewDelegate methods

-(void)mapTouch:(UITapGestureRecognizer *)gestureRecognizer
{
	
    [self dismissAllPopTipViews];
}


- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView {
	[visiblePopTipViews removeObject:popTipView];
	self.currentPopTipViewTarget = nil;
}


- (void)dismissAllPopTipViews {
	while ([visiblePopTipViews count] > 0) {
		CMPopTipView *popTipView = [visiblePopTipViews objectAtIndex:0];
		[visiblePopTipViews removeObjectAtIndex:0];
		[popTipView dismissAnimated:YES];
	}
}


- (void)tip:(id) sender
{
    [self dismissAllPopTipViews];
	
	if (sender == currentPopTipViewTarget) {
		// Dismiss the popTipView and that is all
		self.currentPopTipViewTarget = nil;
	}
	else {
		NSString *contentMessage = nil;
		UIView *contentView = nil;
		id content = [self.contents objectForKey:[NSNumber numberWithInt:[(UIView *)sender tag]]];
		if ([content isKindOfClass:[UIView class]]) {
			contentView = content;
		}
		else if ([content isKindOfClass:[NSString class]]) {
			contentMessage = content;
		}
		else {
			contentMessage = @"A CMPopTipView can automatically point to any view or bar button item.";
		}
		NSArray *colorScheme = [colorSchemes objectAtIndex:0];
		UIColor *backgroundColor = [colorScheme objectAtIndex:0];
		UIColor *textColor = [colorScheme objectAtIndex:1];
		
		CMPopTipView *popTipView;
		if (contentView) {
			popTipView = [[[CMPopTipView alloc] initWithCustomView:contentView] autorelease];
		}
		else {
			popTipView = [[[CMPopTipView alloc] initWithMessage:contentMessage] autorelease];
		}
		popTipView.delegate = self;
		//popTipView.disableTapToDismiss = YES;
		if (backgroundColor && ![backgroundColor isEqual:[NSNull null]]) {
			popTipView.backgroundColor = backgroundColor;
		}
		if (textColor && ![textColor isEqual:[NSNull null]]) {
			popTipView.textColor = textColor;
		}
        
        popTipView.animation = arc4random() % 2;
		
		if ([sender isKindOfClass:[UIButton class]]) {
			UIButton *button = (UIButton *)sender;
			[popTipView presentPointingAtView:button inView:self.view animated:YES];
		}
		else {
			UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
			[popTipView presentPointingAtBarButtonItem:barButtonItem animated:YES];
		}
		
		[visiblePopTipViews addObject:popTipView];
		self.currentPopTipViewTarget = sender;
	}
    
}

- (void)gotoCurrentLocation
{	
	CLLocationCoordinate2D  cood = [APPDEL startPoint].coordinate;
	
    MKCoordinateRegion newRegion;
    
	newRegion.center.latitude = cood.latitude;
	newRegion.center.longitude = cood.longitude;
	newRegion.span = mapView1.region.span;
	//newRegion.span.latitudeDelta = 0.0001;
	//newRegion.span.longitudeDelta = 0.0001;
	
	[self.mapView1 setRegion:newRegion animated:YES];
}


- (void)onCameraView:(id) sender
{
    
	//[playTimeView setHidden:YES];	
	[statusView setHidden:YES];	
	[bCamera setHidden:YES];	
	//[timeOutView setHidden:YES];	
	
	ARGeoViewController *geoViewController = [[ARGeoViewController alloc] init];
	geoViewController.caller = self;
	[self.navigationController pushViewController:geoViewController animated:NO];
    [geoViewController release];
}

- (void)onInfo:(id) sender
{
    NSMutableArray *tempArray = [[[NSMutableArray alloc] init] autorelease];
    NSString *keyString; 
    for(int i = 0; i < [[APPDEL itemTypeKeys] count] ; i++){
        keyString = [[APPDEL itemTypeKeys] objectAtIndex:i];
        if([self.dicRnPTaken objectForKey:keyString] !=nil){
            [tempArray addObject:[NSString stringWithFormat:@"%@ : %@",
                                  [[APPDEL itemType] objectForKey:keyString],[self.dicRnPTaken objectForKey:keyString]]];
            
            NSLog(@"%@ : %@개 획득",[[APPDEL itemType] objectForKey:keyString],[self.dicRnPTaken objectForKey:keyString]);
        }                        
    }
    
    
    NSLog(@"%@",missionDic);
    MissionInfoAlertView *infoAlert = [[MissionInfoAlertView alloc] 
                                       initWithTitle:@"미션정보" 
                                       delegate:nil 
                                       cancelButtonTitle:@"확인" 
                                       otherButtonTitles:nil 
                                       missionDic:self.missionDic 
                                       quiz:missionQuiz 
                                       hints:self.hints 
                                       items:tempArray];
    
    [infoAlert show];
    [infoAlert release];
}


- (void)didReceiveFinished:(NSString *)result
{
    /*
    if (![result isEqualToString:@" SUCCESS"]) {
        [self failAelrt];
    }
     */
}

-(BOOL)uploadMissionPlay:(MissionInPlay *)missionInPlay tran:(NSString *)trName
{
    if (missionState != SERVER_UPLOAD) return NO;
    // 접속할 주소 설정
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정
    NSString *sMissionPlay;
    if ([trName isEqualToString:@"c_mission_play_start"]) {
        sMissionPlay = [NSString stringWithFormat:@"%@,%@,%@,%d",
                        missionInPlay.missionID,           
                        missionInPlay.playerID,        
                        missionInPlay.startTime,
                        isVirtualMode];    
    }
    else if ([trName isEqualToString:@"c_mission_play_finish"]) {
        sMissionPlay = [NSString stringWithFormat:@"%@,%@,%@,%d",
                        missionInPlay.missionID,           
                        missionInPlay.playerID,        
                        missionInPlay.endTime,
                        isVirtualMode];    
    }
    else if ([trName isEqualToString:@"c_mission_play_fail"]) {
        sMissionPlay = [NSString stringWithFormat:@"%@,%@,%@,%d",
                        missionInPlay.missionID,           
                        missionInPlay.playerID,        
                        missionInPlay.endTime,
                        isVirtualMode];    
    }
    else {
        return NO;
    }
    
    // Dictionay 특성 조심 nil 이면 다음 항목 전송 안됨
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                trName,       @"tr",
                                sMissionPlay,           @"mission_play", 
                                nil];
    
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];
	// 페이지 호출
	[httpRequest requestUrl:url bodyObject:bodyObject];
	//[indicator startAnimating];
    
    return YES;
}

- (void)InfoUpdate
{
    
    int numMandatory = 0;
	int numInvisibleMap = 0;
	int numInvisibleAR = 0;
    int numMine = 0;
	
	for (AnnoItem *annoItem in self.mapAnnotations) 
	{
		if ([[self.dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",annoItem.missionItem.itemID]] isEqualToString:@"Y"] == NO )
		{
			if (annoItem.missionItem.mandatory == MANDATORY_Y) 
			{
				numMandatory++;
			}
			
            if ([annoItem.missionItem.itemType isEqualToString:I_MINE]) 
			{
				numMine++;
			}
            
			else if(([annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] || 
                     [annoItem.missionItem.showType isEqualToString:SHOW_AR]) &&
                    [dicRnPTaken valueForKey:I_RADAR_MAP] == nil  &&
                    [dicRnPTaken valueForKey:I_RADAR_ALL] == nil )
			{
				numInvisibleMap++;
			}
			
			else if(([annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] || 
                     [annoItem.missionItem.showType isEqualToString:SHOW_MAP]) &&
                    [dicRnPTaken valueForKey:I_RADAR_AR] == nil  &&
                    [dicRnPTaken valueForKey:I_RADAR_ALL] == nil )			{
				numInvisibleAR++;
			}
		}
	}
	self.mine.text = [NSString stringWithFormat:@"%03d",numMine];
	self.mandatory.text = [NSString stringWithFormat:@"%03d",numMandatory];
	self.invisibleMap.text = [NSString stringWithFormat:@"%03d",numInvisibleMap];
	self.invisibleAR.text = [NSString stringWithFormat:@"%03d",numInvisibleAR];
	
}

- (void)updatePlayInfo
{
	int numMandatory = 0;
	int numInvisibleMap = 0;
	int numInvisibleAR = 0;
    int numMine = 0;
	
	for (AnnoItem *annoItem in self.mapAnnotations) 
	{
		if ([[self.dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",annoItem.missionItem.itemID]] isEqualToString:@"Y"] == NO )
		{
			if (annoItem.missionItem.mandatory == MANDATORY_Y) 
			{
				numMandatory++;
			}
			
			if(([annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] || 
                [annoItem.missionItem.showType isEqualToString:SHOW_AR]) &&
               [dicRnPTaken valueForKey:I_RADAR_MAP] ==  nil  &&
               [dicRnPTaken valueForKey:I_RADAR_ALL] ==  nil )
			{
				numInvisibleMap++;
			}
            else if ([annoItem.missionItem.itemType isEqualToString:I_MINE]) 
			{
				numMine++;
			}
            
			else if(([annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] || 
                     [annoItem.missionItem.showType isEqualToString:SHOW_MAP]) &&
                    [dicRnPTaken valueForKey:I_RADAR_MAP] == nil  &&
                    [dicRnPTaken valueForKey:I_RADAR_ALL] == nil )
			{
				numInvisibleAR++;
			}
		}
	}
	self.mine.text = [NSString stringWithFormat:@"%03d",numMine];
	self.mandatory.text = [NSString stringWithFormat:@"%03d",numMandatory];
	self.invisibleMap.text = [NSString stringWithFormat:@"%03d",numInvisibleMap];
	self.invisibleAR.text = [NSString stringWithFormat:@"%03d",numInvisibleAR];
}

- (BOOL)mineBlast:(MissionItem *) aItem
{
    
    if (self.missionCompleted) return FALSE;
    
    
    MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
    ItemRnPInPlayDao *itemRnPInPlayDao = [[[ItemRnPInPlayDao alloc] init] autorelease];
    //지뢰 아이템 폭파 처리
    MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                            selectWithPK:aItem.missionID
                                            playerID:[APPDEL gUserID] itemID:aItem.itemID];
    
    if ([missionItemInPlay.endYN isEqualToString:@"Y"]) return NO;
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    
    
    
    missionItemInPlay.endYN = (NSMutableString *)@"Y";
    missionItemInPlay.endTime = [NSDate date];
    [missionItemInPlayDao save:missionItemInPlay];
    [self.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.itemID]];
    
    
    [APPDEL playSystemSound:@"s_explosion"  fileType:@"mp3"]; 
    //지뢰 방지 아이템 가지고 있을경우
    int NoBombCnt = 0;
    if ([self.dicRnPTaken valueForKey:I_MINE_NOBOMB] !=  nil)
        NoBombCnt = [[self.dicRnPTaken valueForKey:I_MINE_NOBOMB] intValue];
    
    
    if(NoBombCnt > 0 ) 
    {    
        
        [self blastAlert:0 key:nil];
        //[self.missionDic setValue:[NSString stringWithFormat:@"NobomCnt:%d",NoBombCnt] forKey:@"Title"];
        //지뢰방지 아이템 횟수 축소 
        
        ItemRnPInPlay *NoBombItem = [itemRnPInPlayDao selectWithPK:aItem.missionID 
                                                          playerID:[APPDEL gUserID] itemType:I_MINE_NOBOMB];
        NoBombCnt--;
        NoBombItem.ableCnt = NoBombCnt;
        
        [itemRnPInPlayDao update:NoBombItem];
        
        //[self.missionDic setValue:[NSString stringWithFormat:@"NobomCnt:%d",NoBombCnt] forKey:@"Description"];
        
        self.dicRnPTaken = [itemRnPInPlayDao selectDicAt:aItem.missionID 
                                                playerID:[APPDEL gUserID]];
        
        //지도 갱신
        [self.mapView1 removeAnnotations:self.mapAnnotations];
        [self.mapView1 addAnnotations:self.mapAnnotations];
        [self.mapView1 removeOverlays:self.mapOverlays];
        [self.mapView1 addOverlays:self.mapOverlays];
        
        return NO;
    }
    
    // 최근 획득 아이템 조회
    MissionItemInPlay *lastItemInPlay = [missionItemInPlayDao 
                                         selectLastAcquiredItem:aItem.missionID
                                         playerID:[APPDEL gUserID]
                                         itemID:aItem.itemID];
    
    if (isTimeOutS > 0) {
        self.timeOutStartTime = nil;
        
        self.isTimeOutS = 0;
        self.isTimeOutE = 0;
        [timeOutView setHidden:TRUE];	
        [self.playTimeView setHidden:FALSE];
        
        [self.mapView1 removeAnnotations:self.mapAnnotations];
        [self.mapView1 addAnnotations:self.mapAnnotations];
        [self.mapView1 removeOverlays:self.mapOverlays];
        [self.mapView1 addOverlays:self.mapOverlays];
        
        [self blastAlert:1 key:I_TIMEOUT_S];
        
    }
    else if(lastItemInPlay != nil) 
    {
        
        // 최근 획득 아이템 취소
        lastItemInPlay.endYN = (NSMutableString *)@"N";
        lastItemInPlay.endTime = nil;
        [missionItemInPlayDao update:lastItemInPlay];
        
        
        [self.dicItemEnd setValue:@"N" forKey:[NSString stringWithFormat:@"%d",lastItemInPlay.itemID]];
        
        MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
        MissionItem *lastItem = [missionItemDao selectWithPK:lastItemInPlay.missionID ItemID:lastItemInPlay.itemID];
        
        
        if ([lastItem.itemType isEqualToString:I_START]) {
            MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc]init] autorelease];
            MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:lastItemInPlay.missionID
                                                                 playerID:[APPDEL gUserID]];
            missionInPlay.startYN = (NSMutableString *)@"N";
            missionInPlay.startTime = nil;
            [missionInPlayDao save:missionInPlay];
            
            self.missionStarted = NO;
        }
        else if ([lastItem.itemType isEqualToString:I_TIMEOUT_E]) {
            
            // timeout 시작 아이템 상실 
            
            MissionItemInPlay *relatedItemInPlay = [missionItemInPlayDao 
                                                    selectWithPK:lastItem.missionID
                                                    playerID:[APPDEL gUserID] itemID:lastItem.relationItemID];
            
            relatedItemInPlay.endYN = (NSMutableString *)@"N";
            relatedItemInPlay.endTime = [NSDate date];
            [missionItemInPlayDao save:relatedItemInPlay];
            [self.dicItemEnd setValue:@"N" forKey:[NSString stringWithFormat:@"%d",lastItem.relationItemID]];
            
            
            // timeout 종료 아이템 상실
            MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                    selectWithPK:lastItem.missionID
                                                    playerID:[APPDEL gUserID] itemID:lastItem.itemID];
            
            missionItemInPlay.endYN = (NSMutableString *)@"N";
            missionItemInPlay.endTime = [NSDate date];
            [missionItemInPlayDao save:missionItemInPlay];
            [self.dicItemEnd setValue:@"N" forKey:[NSString stringWithFormat:@"%d",lastItem.itemID]];

            self.timeOutStartTime = [NSDate date];
            self.timeOutLimitTime = lastItem.effectiveTime;
            self.isTimeOutS = lastItem.relationItemID;
            self.isTimeOutE = lastItem.itemID;
            
            self.RunPassTime = [APPDEL sec2timeFormat:self.timeOutLimitTime];
            
            for (int i =0; i < [self._tclockTickers count]; i++) {
                SBTickerView *tickView = [self._tclockTickers objectAtIndex:i];
                [tickView setFrontView:[SBTickView tickViewWithTitle:[self.RunPassTime substringWithRange:NSMakeRange(i, 1)] fontSize:24. backColor:RGBA(255,000,051,1)]];
            }
            
            [self.playTimeView setHidden:TRUE];
            [timeOutView setHidden:FALSE];	
           // [self runStartAelrt];
        }
        ItemRnPInPlayDao *itemRnPInPlayDao = [[[ItemRnPInPlayDao alloc] init] autorelease];
        ItemRnPInPlay *itemRnP = [itemRnPInPlayDao selectWithPK:lastItem.missionID 
                                                       playerID:[APPDEL gUserID] itemType:lastItem.itemType];
        //최근 획득한 아이템 ableCnt 줄이기
        if (itemRnP.ableCnt > 0)
        {
            itemRnP.ableCnt--;
            [itemRnPInPlayDao update:itemRnP];
        }
        
        self.dicRnPTaken = [itemRnPInPlayDao selectDicAt:aItem.missionID 
                                                playerID:[APPDEL gUserID]];
        
        
        [self.mapView1 removeAnnotations:self.mapAnnotations];
        [self.mapView1 addAnnotations:self.mapAnnotations];
        [self.mapView1 removeOverlays:self.mapOverlays];
        [self.mapView1 addOverlays:self.mapOverlays];
        
        [self blastAlert:1 key:lastItem.itemType];
        
    }
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    return NO;
    
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
 
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    if (abs(howRecent) < 15.0 )  
    {
        
        NSLog(@"AppDel latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        
        if(isFirstGps) {
            if(newLocation.horizontalAccuracy < 0.0) return;
            isFirstGps = NO;
        }
        else {
            if(newLocation.horizontalAccuracy < 0.0 || newLocation.horizontalAccuracy > 100.0) return;
        }
        
        if (newLocation != oldLocation) {
            [APPDEL setStartPoint:newLocation];
            
            
            for (AnnoItem *annoItem in self.mapAnnotations) {
                if (self.missionStarted  && [annoItem.missionItem.itemType isEqualToString:I_MINE])
                {
                    CLLocation *itemLoc = [[[CLLocation alloc] initWithLatitude:annoItem.missionItem.latitude 
                                                                      longitude:annoItem.missionItem.longitude] autorelease];
                    
                    if ([newLocation distanceFromLocation:itemLoc] <= annoItem.missionItem.rangeAR)
                        //AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
                        [self mineBlast:annoItem.missionItem];
                }
            }
        }

    }
}

#pragma mark -
#pragma mark AlertView Functions


- (void)finishTimeAlert{
    
    
    
    [APPDEL playSystemSound:@"s_timeover"  fileType:@"mp3"]; 
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    
    NSString *buttonString = NSLocalizedString(@"mission_play_button_1", nil);
    if([APPDEL timeAddCount]>0){
        buttonString = NSLocalizedString(@"mission_play_button_2", nil);
    }
    
    
    NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"mission_play_3", nil) 
                                                              message:[NSString stringWithFormat:@"%@:%@",
                                                                       NSLocalizedString(@"mission_play_4", nil),
                                                                       [APPDEL toNSString:self.runLimitTime :@"HH:mm:ss"]]
                                                               cancel:NSLocalizedString(@"mission_play_button_0", nil)
                                                                   ok:buttonString
                                                             itemType:nil];
    
    alertView.tag = 1;
    [alertView show];
    [alertView setDelegate:self];
    [alertView release];
    [dateFormatter release];
}
- (void)finishRunTimeAlert{
    
    [APPDEL playSystemSound:@"s_timeover"  fileType:@"mp3"]; 
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    
    NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"mission_play_9", nil) 
                                                              message:[NSString stringWithFormat:@"%@:%@",
                                                                       NSLocalizedString(@"mission_play_10", nil),
                                                                       [APPDEL sec2timeFormat:self.timeOutLimitTime]]
                                                               cancel:NSLocalizedString(@"ok", nil)
                                                                   ok:nil
                                                             itemType:nil];   
    [alertView show];
    [alertView release];
    [dateFormatter release];
}

- (void)failAelrt {
    NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"save_fail", nil) 
                                                              message:NSLocalizedString(@"save_fail_message", nil)
                                                               cancel:NSLocalizedString(@"ok", nil)
                                                                   ok:nil
                                                             itemType:nil];
    [alertView show];
    [alertView release];  
}

- (void)runStartAelrt {
    
    NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"obtain_run_start", nil) 
                                                              message:NSLocalizedString(@"obtain_run_start_info", nil)
                                                               cancel:NSLocalizedString(@"ok", nil)
                                                                   ok:nil
                                                             itemType:nil];
    
    [alertView show];
    [alertView release];  
}

- (void)finishAlert{   
    
    NSString *rtime;
    if (runLimitTime == nil) {
        rtime = [NSString stringWithFormat:@"%@:%@:%@",[passTime substringWithRange:NSMakeRange(0, 2)],
                 [passTime substringWithRange:NSMakeRange(2, 2)],
                 [passTime substringWithRange:NSMakeRange(4, 2)]];
    }
    else {
        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
        [dateFormatter setDateFormat:@"HHmmss"];
        
        NSDate* limit = [dateFormatter dateFromString:[APPDEL toNSString:self.runLimitTime :@"HHmmss"]];
        NSDate* passed = [dateFormatter dateFromString:passTime];
        
        NSTimeInterval timeDifference = [limit timeIntervalSinceDate:passed];
        
        NSLog(@"%f",timeDifference);
        
        NSUInteger seconds = (NSUInteger)round(timeDifference);
        rtime = [NSString stringWithFormat:@"%02u:%02u:%02u", seconds / 3600, (seconds / 60) % 60, seconds % 60];
    }
    
    if (missionState == SERVER_UPLOAD) {
        [[APPDEL playedArray] addObject:missionDic];
        
        TextAlertView *mTextAlertView = [[TextAlertView alloc]
                                         initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"mission_play_finish1", nil),rtime] 
                                         message:[NSString stringWithFormat:@"%@\n\n\n\n",NSLocalizedString(@"mission_play_finish2", nil)] 
                                         delegate:self 
                                         cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                         okButtonTitle:nil];
        
        mTextAlertView.tag = 0;
        [mTextAlertView show];
        [mTextAlertView release];
        
    }
    else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        
        
        NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"mission_play_test1", nil) 
                                                                  message:[NSString stringWithFormat:@"%@ \n %@ ",
                                                                           rtime, 
                                                                           NSLocalizedString(@"mission_play_test2", nil)]
                                                                   cancel:NSLocalizedString(@"ok", nil)
                                                                       ok:nil
                                                                 itemType:nil];
        
        [alertView show];
        [alertView release];
        [dateFormatter release];
    }
}



- (void)blastAlert:(int)kind key:(NSString*)key{
    NSString *message = NSLocalizedString(@"mission_play_6", nil);
    if(kind ==1){
        message = [NSString stringWithFormat:NSLocalizedString(@"mission_play_7", nil),
                   [[APPDEL itemType] valueForKey:key ]];
    }
    
    NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"mission_play_8", nil) 
                                                              message:message
                                                               cancel:NSLocalizedString(@"ok", nil)
                                                                   ok:nil
                                                             itemType:nil];
    
    [alertView show];
    [alertView release]; 
}

- (void) increaseTimeAlert{
    
    NoticAlertView *alertView = [[NoticAlertView alloc] initWithTitle:NSLocalizedString(@"mission_play_time_0", nil) 
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"mission_play_time_1", nil), [APPDEL timeAddCount]]
                                                               cancel:NSLocalizedString(@"cancel", nil)
                                                                   ok:NSLocalizedString(@"ok", nil)
                                                             itemType:nil];
    [alertView setTag:2];
    [alertView setDelegate:self];
    [alertView show];
    [alertView release]; 
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex  
{
    if(alertView.tag == 0){
        [SVProgressHUD showWithStatus:@"Loading.."];
        NSString *reply = [(TextAlertView *)alertView enteredText];
        float rate =  [(TextAlertView *)alertView starRate];
        
        
        HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
        NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"400",@"tr",
                                    missionID, @"MID",
                                    [APPDEL gUserID],@"UID",
                                    [NSString stringWithFormat:@"%f",rate],@"Score",
                                    reply,@"Reply",
                                    nil];
        NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
        [httpRequest requestUrl:url bodyObject:bodyObject];
        [self httpSendPlayed];
        
    }else if (alertView.tag == 1) {
        if(buttonIndex == 4){
            
            
            MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc] init] autorelease];
            MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
            ItemRnPInPlayDao *itemRnPInPlayDao = [[[ItemRnPInPlayDao alloc] init] autorelease];
            
            
            
            MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:self.missionID playerID:[APPDEL gUserID]];
            missionInPlay.endYN = (NSMutableString *)@"F";
            missionInPlay.endTime = [NSDate date];
            [self uploadMissionPlay:missionInPlay tran:@"c_mission_play_fail"];
            
            
            [missionInPlayDao deleteAt:self.missionID playerID:[APPDEL gUserID]];
            [missionItemInPlayDao deleteAt:self.missionID playerID:[APPDEL gUserID]];
            [itemRnPInPlayDao deleteAt:self.missionID playerID:[APPDEL gUserID]];
            
            
            
            [self finishGame];
            
            
        }else if(buttonIndex == 5){
            if([APPDEL timeAddCount]>0){
                [self increaseTimeAlert];
            }else if(!onBuy){
                [self startPayment:@"time_add_10"];
    
            }
        }
        
        return;
	}else if(alertView.tag == 2){
        if(buttonIndex == 5){
            
            for (int i =0; i < [_clockTickers count]; i++) {
                SBTickerView *tickView = [_clockTickers objectAtIndex:i];
                [tickView setFrontView:[SBTickView tickViewWithTitle:[passTime substringWithRange:NSMakeRange(i, 1)] fontSize:24. backColor:RGBA(30, 30, 30,1)]];
            }
            //미션 제한 시간 증가 : timer 재시작및 시간증가
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:self.runLimitTime];
            NSInteger hour = [components hour];
            NSInteger minute = [components minute];
            NSInteger sec = [components second];
            
            double ss =  hour * 3600 + minute * 60 + sec;
            // 제한 시간에서 빼야 되므로 30% 아닌 70%로
            // 시간 2배로 
            double incTime = ss;
            
            /*
             double incRunTime = ss * 1.3;
             self.runLimitTime =  [[NSDate date] dateByAddingTimeInterval:incRunTime];
             */
            
            
            
            //self.missionStartTime =  [[NSDate date] dateByAddingTimeInterval:-incTime];
            self.missionStartTime =  [NSDate date];
            
            MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc]init] autorelease];
            MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:self.missionID
                                                                 playerID:[APPDEL gUserID]];
            missionInPlay.startTime = self.missionStartTime;            
            [missionInPlayDao save:missionInPlay];
            
            //이거 랭킹을 위해서 막아야 되남?
            [self uploadMissionPlay:missionInPlay tran:@"c_mission_play_start"];
            
            
            if (passedTimer) {
                [passedTimer invalidate];
                 passedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                               target:self
                                                             selector:@selector(updatePassedTime:)
                                                             userInfo:nil
                                                              repeats:YES];
            }
            
            
            int count = [APPDEL timeAddCount]-1;
            [APPDEL setTimeAddCount:count];
        }else{
            [self finishTimeAlert];
        }
    } else if (alertView.tag == 100) {
        if (buttonIndex == 5) {
            [self finishGame];
        }
    }
}

- (void) finishGame{
    [statusView removeFromSuperview];
    [timeOutView removeFromSuperview];
    [playTimeView removeFromSuperview];
    [bCamera removeFromSuperview];
    
    
    [self.navigationController popViewControllerAnimated:YES];
    
    if(passedTimer != nil){
        [passedTimer invalidate];
        passedTimer = nil;
    }
    [APPDEL locationManager].delegate = nil;
    [[APPDEL locationManager] stopUpdatingLocation];
    [[APPDEL locationManager] stopUpdatingHeading];
}


- (void)httpSendPlayed
{
    
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"601",@"tr",
                                [APPDEL gUserID],@"id", nil];
    
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
    
    [httpRequest setDelegate:self selector:@selector(didReceivePlayFinished:)];
    
	// 페이지 호출
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
    
}

- (void)didReceivePlayFinished:(NSString *)result
{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        
        if(svrArr !=nil){
            [[APPDEL playedArray] removeAllObjects];
            [[APPDEL playedArray] addObjectsFromArray:svrArr]; 
            [APPDEL setPlayedCount:[[APPDEL playedArray] count]];
            for(int i = 0 ; i < [APPDEL playedCount] ; i++){
                [APPDEL checkNAddImg:[[[APPDEL playedArray] objectAtIndex:i]objectForKey:@"MissionID"]];
            }
        }
    }
    [SVProgressHUD dismiss];
    [self ExitClick];
    [missionDetail getMissionReply];
}

#pragma mark -
#pragma mark Payment Functions

- (void) startPayment:(NSString*)productID{
    
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productID]; 
    if(payment !=nil){
        onBuy = true;
        [SVProgressHUD showWithStatus:NSLocalizedString(@"purchase", nil)];
        [[SKPaymentQueue defaultQueue] addPayment:payment];  
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:				
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
    [self resultbuy];
    [SVProgressHUD dismiss];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
    [self failAlert];
    [SVProgressHUD dismiss];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
    [self resultbuy];
    [SVProgressHUD dismiss];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
- (void) resultbuy{
    int count = 10+ [APPDEL timeAddCount];
    [APPDEL setTimeAddCount:count];
    [self increaseTimeAlert];
}


- (void) failAlert{
    if(onBuy){
        onBuy = false;
        UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:NSLocalizedString(@"purchase_2", nil)
                                  message:NSLocalizedString(@"purchase_3", nil)
                                  delegate:self 
                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        [alertView release];
    }
    
}


#pragma mark -
#pragma mark Ex Functions

-(UIImage *)convertImageBW:(UIImage *)originalImage
{
	if (originalImage == nil) {
		return nil;
	}
	CGImageRef originalCgImage = [originalImage CGImage];
	CGDataProviderRef provider = CGImageGetDataProvider(originalCgImage);
	CFDataRef bitmapData = CGDataProviderCopyData(provider);
    unsigned char *pixelBuffer = (unsigned char *)CFDataGetBytePtr(bitmapData);
    CFRelease(bitmapData);
    
    size_t length = originalImage.size.width * originalImage.size.height * 4;
    CGFloat intensity;
    int bw;
    for (int index = 0; index < length; index += 4)  
    {  
        intensity = (pixelBuffer[index] + pixelBuffer[index + 1] + pixelBuffer[index + 2]) / 3. / 255.;
		bw = 255 * intensity;
        pixelBuffer[index] = bw;
		pixelBuffer[index + 1] = bw;  
        pixelBuffer[index + 2] = bw;
    }
	
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext=CGBitmapContextCreate(pixelBuffer, originalImage.size.width, originalImage.size.height, 8, 4*originalImage.size.width, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CFRelease(colorSpace);
    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
	
    UIImage *bwImage = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return bwImage;
}

-(UIImage *)convertImageYellow:(UIImage *)originalImage
{
	if (originalImage == nil) {
		return nil;
	}
    
	CGImageRef originalCgImage = [originalImage CGImage];
	CGDataProviderRef provider = CGImageGetDataProvider(originalCgImage);
	CFDataRef bitmapData = CGDataProviderCopyData(provider);
    unsigned char *pixelBuffer = (unsigned char *)CFDataGetBytePtr(bitmapData);
    CFRelease(bitmapData);
	
    size_t length = originalImage.size.width * originalImage.size.height * 4;
    CGFloat intensity;
    int bw;
    for (int index = 0; index < length; index += 4)  
    {  
        intensity = (pixelBuffer[index] + pixelBuffer[index + 1] + pixelBuffer[index + 2]) / 3. / 255.;
		bw = 255 * intensity;
        pixelBuffer[index] = bw;
		pixelBuffer[index + 1] = bw;  
        pixelBuffer[index + 2] = 0;
    }
	
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext=CGBitmapContextCreate(pixelBuffer, originalImage.size.width, originalImage.size.height, 8, 4*originalImage.size.width, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CFRelease(colorSpace);
    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
	
    UIImage *bwImage = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return bwImage;
}



+ (CGFloat)annotationPadding;
{
	return 10.0f;
}
+ (CGFloat)calloutHeight;
{
	return 40.0f;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{
	if(self.missionStarted)
	{
        
        CircleItem *_tmpItem = (CircleItem *)overlay;
		MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
        
        
        if([_tmpItem.missionItem.itemType isEqualToString:I_MINE])
        {
            if ([dicRnPTaken valueForKey:I_RADAR_MINE] != nil || 
                [(NSString *)[dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]] isEqualToString:@"Y"])
            {
                
                MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
                MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                        selectWithPK:_tmpItem.missionItem.missionID
                                                        playerID:[APPDEL gUserID] itemID:_tmpItem.missionItem.itemID];
                
                if ([missionItemInPlay.endYN isEqualToString:@"Y"]) {
                    
                    circleView.fillColor = RGBA(139,69,39,1);
                    circleView.alpha = 0.3;
                }else {
                    circleView.fillColor = [UIColor redColor];
                    circleView.alpha = 0.4;
                }    
                
            }
            
            
        }
        else if([_tmpItem.missionItem.itemType isEqualToString:I_BLACK]) {
            circleView.fillColor = [UIColor blackColor];
            circleView.alpha = 0.3;
        }
        return [circleView autorelease];
	}
	else {
		return nil;
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	// no pin if this is the user location.  we want the dot and concnetric circle, and continual updates.
	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
	
	// handle our two custom annotations
	//
	if ([annotation isKindOfClass:[AnnoItem class]]) // for Golden Gate Bridge
	{
		// try to dequeue an existing pin view first
		
		AnnoItem *_tmpItem = (AnnoItem *)annotation;
		if (_tmpItem != nil) {
			
            NSString *man;
            
            if ([self.mandatory.text intValue] == 1)
                man = @"1";
            else 
                man =@"0";
            
            NSString *identifier = [NSString stringWithFormat:@"%@%d%d%d%@%d",
                                    [dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]],
                                    _tmpItem.missionItem.itemID,
                                    [dicRnPTaken count],
                                    self.missionStarted,                                
                                    man,
                                    isTimeOutE
                                    ];
            
            /*
             NSString *identifier = [NSString stringWithFormat:@"%@%@%d%@%@%@%@%@%d", _tmpItem.missionItem.itemID,
             [dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]],
             self.missionStarted,
             [dicRnPTaken valueForKey:I_RADAR_MAP],
             [dicRnPTaken valueForKey:I_RADAR_ALL],
             [dicRnPTaken valueForKey:I_RADAR_MINE],
             [dicRnPTaken valueForKey:I_MINE],
             man,
             isTimeOutE
             ];
             */
			
            
			MKAnnotationView *pinView = nil;
			pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
			NSLog(@"mapView viewForAnnotation:%@",identifier);
            
			if (!pinView || isTimeOutE > 0)
			{
				MKAnnotationView* customPinView = [[[MKAnnotationView alloc] initWithAnnotation:annotation 
                                                                                reuseIdentifier:identifier] autorelease];
				customPinView.tag = 8;
				customPinView.canShowCallout = YES;
				
				CGRect resizeRect;
				NSString *imgFile;
				if (_tmpItem.missionItem.mandatory == MANDATORY_Y)
				{
					imgFile = [APPDEL itemMandatoryMapFile:_tmpItem.missionItem.itemType];
				}
				else
				{
					imgFile = [APPDEL itemMapFile:_tmpItem.missionItem.itemType];
				}
				
				if(![_tmpItem.missionItem.itemType isEqualToString:I_START] &&
                   missionStarted == NO) {
					imgFile = nil;
					customPinView.canShowCallout = NO;
				}
                if([_tmpItem.missionItem.itemType isEqualToString:I_MINE] &&
                   [(NSString *)[dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]] isEqualToString:@"N"]) 
                {
                    /*
                     for (id key in dicRnPTaken) {
                     NSLog(@"key: %@, value: %@", key, [dicRnPTaken objectForKey:key]);   
                     }                    */
                    
                    if ([dicRnPTaken valueForKey:I_RADAR_MINE] == nil)
                    {
                        imgFile = nil;
                        customPinView.canShowCallout = NO;
                    }
                }
                
				if ([_tmpItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] || 
                    [_tmpItem.missionItem.showType isEqualToString:SHOW_AR]) 
                {
					if([dicRnPTaken valueForKey:I_RADAR_MAP] == nil &&
                       [dicRnPTaken valueForKey:I_RADAR_ALL]  ==  nil &&
                       [(NSString *)[dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]] 
                        isEqualToString:@"Y"] == NO) {
                           imgFile = nil;
                           customPinView.canShowCallout = NO;
                       }			
				}
                if([_tmpItem.missionItem.itemType isEqualToString:I_END] && [self.mandatory.text intValue] > 1)
                {
					imgFile = nil;
					customPinView.canShowCallout = NO;
				}
                CLLocation *tmpItemLoc = [[CLLocation alloc] initWithLatitude:_tmpItem.missionItem.latitude 
                                                                    longitude:_tmpItem.missionItem.longitude];
				for (CircleItem *circleItem in self.mapOverlays)
				{
                    if([circleItem.missionItem.itemType isEqualToString:I_BLACK] && 
                       [(NSString *)[dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]] 
                        isEqualToString:@"Y"] == NO)
                    {
                        CLLocation *circleItemLoc = [[CLLocation alloc] initWithLatitude:circleItem.missionItem.latitude 
                                                                               longitude:circleItem.missionItem.longitude];
                        if ([circleItemLoc distanceFromLocation:tmpItemLoc] <= circleItem.missionItem.rangeAR &&
                            ![_tmpItem.missionItem.itemType isEqualToString:I_START])
                        {
                            if ([_tmpItem.missionItem.itemType isEqualToString:I_BLACK])
                            {
                                [circleItemLoc release];
                                break;
                            }  
                            else{
                                imgFile = nil;
                                customPinView.canShowCallout = NO;
                                [circleItemLoc release];
                                break;
                            }
                            
                        }
						
						[circleItemLoc release];
                    }
				}
				
				[tmpItemLoc release];
                
				
				UIImage *flagImage = [UIImage imageNamed:imgFile];
                
                if([(NSString *)[dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]] 
                    isEqualToString:@"Y"]) {				
					flagImage = [self convertImageBW:flagImage];
				}
                //20고개 문제만 봤을 경우 20으로  yellow로 
                /*
                 else if([(NSString *)[dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",_tmpItem.missionItem.itemID]] 
                 isEqualToString:@"G"]) {				
                 flagImage = [self convertImageYellow:flagImage];
                 }
                 */
                
				resizeRect.size = flagImage.size;
				
				CGSize maxSize = CGRectInset(self.view.bounds,
                                             [MissionPlay annotationPadding],
                                             [MissionPlay annotationPadding]).size;
				maxSize.height -= self.navigationController.navigationBar.frame.size.height + [MissionPlay calloutHeight];
				if (resizeRect.size.width > maxSize.width)
					resizeRect.size = CGSizeMake(maxSize.width, resizeRect.size.height / resizeRect.size.width * maxSize.width);
				if (resizeRect.size.height > maxSize.height)
					resizeRect.size = CGSizeMake(resizeRect.size.width / resizeRect.size.height * maxSize.height, maxSize.height);
				
				resizeRect.origin = (CGPoint){0.0f, 0.0f};
				UIGraphicsBeginImageContext(resizeRect.size);
				
				[flagImage drawInRect:resizeRect];
				
				UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
				
				customPinView.image = resizedImage;
                
                if(_tmpItem.missionItem.itemID == isTimeOutE) 
                {
                    customPinView.layer.contents = (id)customPinView.image.CGImage;
                    customPinView.layer.bounds = CGRectMake(0, 0, customPinView.image.size.width, customPinView.image.size.height);
                    
                    // Shrink down to 90% of its original value
                    customPinView.layer.transform = CATransform3DMakeScale(1.50, 1.50, 1);
                    
                    [self.view.layer addSublayer:customPinView.layer];
                    
                    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
                    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
                    animation.autoreverses = YES;
                    animation.duration = 0.35;
                    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    animation.repeatCount = HUGE_VALF;
                    [customPinView.layer addAnimation:animation forKey:@"pulseAnimation"];
                    
                }
				else if(isTimeOutE == 0 && [_tmpItem.missionItem.itemType isEqualToString:I_TIMEOUT_E])
                {
                    [customPinView.layer removeAnimationForKey:@"pulseAnimation"];
                }
                
				if (![_tmpItem.missionItem.itemType isEqualToString:I_MINE])
				{
					customPinView.opaque = NO;
					customPinView.centerOffset = CGPointMake(0,-resizeRect.size.height / 2);
				}
				
				return customPinView;
			}
			else
			{
				pinView.annotation = annotation;
			}
			return pinView;
			
		}
		
	}
	
	return nil;
	
}
/*
 - (void)mapView:(MKMapView *)theMapView didUpdateUserLocation:(MKUserLocation *)userLocation
 {
 
 }
 */
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    
	NSLog(@"MissionPlay:didReceiveMemoryWarning");
	[super didReceiveMemoryWarning];
	[[APPDEL playingDic] setObject: [NSNumber numberWithInt:0] forKey:@"isNewStart"];
	// Release any cached data, images, etc. that aren't in use.
}


@end
