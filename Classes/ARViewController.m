//
//  ARKViewController.m
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import "ARViewController.h"
#import "ARGeoCoordinate.h"
#import "MissionDao.h"
#import "MissionInPlayDao.h"
#import "MissionInPlay.h"
#import "MissionItemInPlayDao.h"
#import "MissionItemInPlay.h"
#import "MissionItemDao.h"
#import "ItemRnPInPlayDao.h"
#import "ItemRnPInPlay.h"

#import "MissionPlay.h"
#import "QuizPlayAlert.h"
#import "GamePlayAlert.h"
#import "SBTickerView.h"
#import "SBTickView.h"
#import "NoticAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import "SVProgressHUD.h"
#import "TextAlertView.h"

#define VIEWPORT_WIDTH_RADIANS .5
#define VIEWPORT_HEIGHT_RADIANS .7392
//#define degreesToRadians(x) (M_PI * (x) / 180.0)

@implementation ARViewController

@synthesize accelerometerManager;
@synthesize centerCoordinate;

@synthesize scaleViewsBasedOnDistance, rotateViewsBasedOnPerspective;
@synthesize maximumScaleDistance;
@synthesize minimumScaleFactor, maximumRotationAngle;

@synthesize coordinates = ar_coordinates;
@synthesize delegate, locationDelegate, accelerometerDelegate;
@synthesize cameraController;

@synthesize caller,randItems;

@synthesize imgItemView;

@synthesize colorSchemes;
@synthesize contents=_contents;
@synthesize currentPopTipViewTarget;
@synthesize visiblePopTipViews;


#pragma mark -
#pragma mark life cycle

-(void)CameraOpen
{
#if !TARGET_IPHONE_SIMULATOR
	
	self.cameraController = [[[UIImagePickerController alloc] init] autorelease];
	self.cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	self.cameraController.cameraViewTransform = CGAffineTransformScale(self.cameraController.cameraViewTransform,
                                                                       1.0f,
                                                                       1.25f);
	
	self.cameraController.showsCameraControls = NO;
	self.cameraController.navigationBarHidden = YES;
	self.cameraController.toolbarHidden = YES;
    ar_overlayView.backgroundColor = [UIColor clearColor]; 
    [self.cameraController setCameraOverlayView:ar_overlayView];
	[self presentModalViewController:self.cameraController animated:NO];
	[ar_overlayView setFrame:self.cameraController.view.bounds];
    
#endif
    
    [APPDEL playSystemSound:@"s_radar" fileType:@"mp3"];
    [self startTimer];
    
	
	ar_infoView.tag = 20;
    [ar_infoView addTarget:self action:@selector(tip:)  forControlEvents:UIControlEventTouchUpInside];
    
    ar_infoView1.tag = 21;
    [ar_infoView1 addTarget:self action:@selector(tip:)  forControlEvents:UIControlEventTouchUpInside];
    
    ar_radar.tag = 22;
    [ar_radar addTarget:self action:@selector(tip:)  forControlEvents:UIControlEventTouchUpInside];
    
    self.visiblePopTipViews = [NSMutableArray array];
    self.contents = [NSDictionary dictionaryWithObjectsAndKeys:
					 // Rounded rect buttons
					 NSLocalizedString(@"ar_tip1", nil), [NSNumber numberWithInt:20],
					 NSLocalizedString(@"ar_tip2", nil), [NSNumber numberWithInt:21],
                     NSLocalizedString(@"ar_tip3", nil), [NSNumber numberWithInt:22],
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

}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    [self performSelector:@selector(CameraOpen) withObject:nil afterDelay:0];    
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	NSLog(@"ARViewController:didReceiveMemoryWarning");
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    NSLog(@"ARViewController:viewDidUnload");
    /*
	[ar_overlayView release]; ar_overlayView = nil;
    [ar_infoView release];  ar_infoView = nil;
	[ar_infoView1 release]; ar_infoView1 = nil;
    [ar_radar release]; ar_radar = nil;
    [radianPhone release];  radianPhone =nil;
    [radianItem release];   radianItem = nil;
    [mapButton release];    mapButton = nil;
    [ar_coordinateViews release];   ar_coordinateViews = nil;
	[ar_coordinates release];   ar_coordinates =nil;
    [minDistItem release];  minDistItem = nil;
	[minDistItemInView release]; minDistItemInView = nil;
    */
	self.randItems =nil;
    self.caller= nil;
	self.accelerometerManager.delegate = nil;
    self.accelerometerManager = nil;
    self.contents=nil;
    self.colorSchemes=nil;
    self.currentPopTipViewTarget=nil;
    self.visiblePopTipViews=nil;
    self.imgItemView = nil;

    [self stopTimer];
   
}


- (void)dealloc {
    NSLog(@"ARViewController:dealloc");

    self.randItems =nil;
    self.caller= nil;
	self.accelerometerManager.delegate = nil;
    self.accelerometerManager = nil;
    self.contents=nil;
    self.colorSchemes=nil;
    self.currentPopTipViewTarget=nil;
    self.visiblePopTipViews=nil;
    self.imgItemView = nil;

  	[ar_overlayView release]; 
    [ar_infoView release];
	[ar_infoView1 release];
    [ar_radar release];
    [radianPhone release];
    [mapButton release];
    
    [radianItem release];
    [ar_coordinateViews release];
	[ar_coordinates release];
    [minDistItem release];
	[minDistItemInView release];
    [accelerometerManager release];
	[caller release];
	[randItems release];
	
	[imgItemView release];
    
    [_contents release];
	[colorSchemes release];
	[currentPopTipViewTarget release];
	[visiblePopTipViews release];
    
    [self stopTimer];
    
	[super dealloc];
}

- (id)init {
	if (!(self = [super init])) return nil;
	
	ar_infoView = nil;
	ar_infoView1 = nil;
    ar_radar = nil;
	ar_overlayView = nil;
    
    
    shakeEnable = TRUE;
    
	// randItems = [[NSMutableArray alloc] init]; 
	ar_coordinates = [[NSMutableArray alloc] init];
	ar_coordinateViews = [[NSMutableArray alloc] init];
	minDistItem = [[ARCoordinate alloc]init];
	minDistItemInView = [[ARCoordinate alloc]init];
	minDistItemInView.radialDistance = 9999999;
	//_updateTimer = nil;
    
  	self.scaleViewsBasedOnDistance = NO;
	self.maximumScaleDistance = 0.0;
	self.minimumScaleFactor = 1.0;
	
	self.rotateViewsBasedOnPerspective = NO;
	self.maximumRotationAngle = M_PI / 6.0;
	
	self.wantsFullScreenLayout = YES;
    
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    
	ar_overlayView = [[UIView alloc] initWithFrame:CGRectZero];
    
    ar_overlayView.backgroundColor = [UIColor blackColor];
	
	UIImage *imgPanel = [UIImage imageNamed:@"radar_body.png"];
	UIImage *imgCenter = [UIImage imageNamed:@"radar_cross.png"];
	UIImage *imgItem = [UIImage imageNamed:@"radar_item.png"];
	UIImage *imgPhone = [UIImage imageNamed:@"radar_myway.png"];
	UIImage *imgMapButton = [UIImage imageNamed:@"button_map.png"];
	
	UIImageView *radianPanel = [[UIImageView alloc] initWithImage:imgPanel];
	UIImageView *radianCenter = [[UIImageView alloc] initWithImage:imgCenter];
	radianItem = [[UIImageView alloc] initWithImage:imgItem];
	radianPhone = [[UIImageView alloc] initWithImage:imgPhone];
    
	[radianPanel setFrame:CGRectMake(0, 0, 319, 61)];
	[radianCenter setFrame:CGRectMake(0, 0, 61, 61)];
	[radianItem setFrame:CGRectMake(0,0,11,25)];
	[radianPhone setFrame:CGRectMake(0,0,33,28)];
	[radianPanel setCenter:CGPointMake(160, 451)];
	[radianCenter setCenter:CGPointMake(160, 451)];
	[radianItem setCenter:CGPointMake(160,451)];
	[radianPhone setCenter:CGPointMake(160,451)];
	[radianPanel setAlpha:1.0f];
	[radianCenter setAlpha:1.0f];
	[radianItem setAlpha:1.0f];
	[radianPhone setAlpha:1.0f];
	radianPhone.layer.anchorPoint = CGPointMake(0.5f,1.0f);
	radianItem.layer.anchorPoint = CGPointMake(0.5f,1.0f);
	
	[ar_overlayView addSubview:radianPanel];
	[ar_overlayView addSubview:radianCenter];
	[ar_overlayView addSubview:radianPhone];
	[ar_overlayView addSubview:radianItem];
    
    [radianPanel release];
    [radianCenter release];
    
	ar_infoView = [UIButton buttonWithType:UIButtonTypeCustom];
    [ar_infoView retain];
	ar_infoView.titleLabel.font = [UIFont boldSystemFontOfSize:13];
	ar_infoView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	[ar_infoView setTitle:@"" forState:UIControlStateNormal];

	[ar_overlayView addSubview:ar_infoView];
	
	ar_infoView1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [ar_infoView1 retain];
	ar_infoView1.titleLabel.font = [UIFont boldSystemFontOfSize:13];
	ar_infoView1.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	[ar_infoView1 setTitle:@"Waiting..." forState:UIControlStateNormal];

	[ar_overlayView addSubview:ar_infoView1];
	
    
    ar_radar = [UIButton buttonWithType:UIButtonTypeCustom];   
    [ar_radar retain];
	[ar_overlayView addSubview:ar_radar];
    
	[ar_infoView setFrame:CGRectMake(0,
                                     440,
                                     145,
                                     40)];	
	
	[ar_infoView1 setFrame:CGRectMake(180,
                                      440,
                                      145,
                                      40)];	
    
    [ar_radar setFrame:CGRectMake(133,
                                  430,
                                  60,
                                   60)];	
	self.view = ar_overlayView;
	
	mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [mapButton retain];
	mapButton.frame = CGRectMake(0, 0, 65, 30);
	[mapButton setBackgroundImage:imgMapButton forState:UIControlStateNormal];
	[mapButton addTarget:self action:@selector(onMapView:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:mapButton];

	
    
    //[ar_overlayView addSubview:caller.playTimeView];
}



#pragma mark -
#pragma mark touch methods
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self dismissAllPopTipViews];
	CGPoint currentPos = [[touches anyObject] locationInView:self.view];
	if(CGRectContainsPoint(imgItemView.frame,currentPos)) {
		[self getItemAnimation];
	}
}


- (void)animationDidStop:(NSString *)animID finished:(BOOL)didFinish context:(void *)context 
{
	if( [animID isEqualToString:@"Bounce"]){
		NSLog(@"Bounce animation finished.");		
		[UIView beginAnimations:@"ended" context:NULL];
		[UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
		[UIView setAnimationDuration:.3];
		[UIView setAnimationBeginsFromCurrentState:YES];
		imgItemView.transform = CGAffineTransformMakeScale(1, 1);
		[imgItemView setFrame:CGRectMake(0,0,0,0)];
		[imgItemView setCenter:CGPointMake(160,480)];
		[UIView commitAnimations];
		
	} else if ( [animID isEqualToString:@"ended"] ) {
		[self startTimer];
	} 
}

#pragma mark -
#pragma mark CMPopTipViewDelegate methods

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
			contentMessage = @"Play Spot 만세!";
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
        
        // 메모리 워닝 테스트
        //[caller didReceiveMemoryWarning];
        //[self didReceiveMemoryWarning];
	}
    
}


- (void)getItemAnimation
{
	static NSDate *prevStart = nil;
	
	if (prevStart == nil) {
		prevStart = [[NSDate alloc]initWithTimeIntervalSince1970:600.0f];
	}
	
	NSDate *now = [[NSDate alloc] init];
	NSDate *checkDate = [[NSDate alloc] initWithTimeInterval:0.5f sinceDate:prevStart];
	
	NSLog(@"now:%@",now);
	NSLog(@"checkDate:%@",checkDate);
	NSLog(@"[now compare:checkDate]:%d",[now compare:checkDate]);
	
	if([now compare:checkDate] == NSOrderedDescending)
	{
		[now release];
		[checkDate release];
		
		[prevStart release];
		prevStart = [[NSDate alloc] init];
	}
	else {
		[now release];
		[checkDate release];
		return;
	}
	
	if (minDistItemInView.radialDistance == 9999999) {
		return;
	}
    
	if ([[caller.dicItemEnd  valueForKey:[NSString stringWithFormat:@"%d",minDistItemInView.annoItem.missionItem.itemID]] isEqualToString:@"Y"]) {
		return;
	}
    
    
    [self stopTimer];
	
	[UIView beginAnimations:@"Bounce" context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:.3];
	imgItemView.transform = CGAffineTransformMakeScale(1.5, 1.5);
	[UIView commitAnimations];
	
	
	
	outstandingItem = minDistItemInView.annoItem.missionItem;
    
	if([outstandingItem.itemType isEqualToString:I_START] == NO) {
		if(caller.missionStarted == NO) {
			return;
		}
	}
	
	
    [self getItem:outstandingItem];
}


- (void)missionSuccess:(MissionItem *) aItem
{
    MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
    MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                            selectWithPK:aItem.missionID
                                            playerID:[APPDEL gUserID] itemID:aItem.itemID];
    //[self playSound:completedSound];   
    [APPDEL playSystemSound:@"s_applause"  fileType:@"mp3"]; 
    missionItemInPlay.endYN = (NSMutableString *)@"Y";
    missionItemInPlay.endTime = [NSDate date];
    [missionItemInPlayDao save:missionItemInPlay];
    
    [caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.itemID]];
    
    
    MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
	Mission *mission = [missionDao selectWithPK:caller.missionID];
    
    if (mission.mStatus == DESIGNING) {
        mission.mStatus =  TESTED;
        [missionDao save:mission];
        
        Mission *mission = [[[Mission alloc] init] autorelease];
        [mission getDBBuildMissions];
        
    }
    else {
        MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc]init] autorelease];
        MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:aItem.missionID playerID:[APPDEL gUserID]];
        missionInPlay.endYN = (NSMutableString *)@"Y";
        missionInPlay.endTime = [NSDate date];
        [missionInPlayDao save:missionInPlay];
        [caller uploadMissionPlay:missionInPlay tran:@"c_mission_play_finish"];
    }
    
    caller.missionCompleted = YES;
    
    [self mapInfoUpdate:TRUE];
}

- (void)getItem:(MissionItem *) aItem
{
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    
    [SVProgressHUD dismiss];
    outstandingItem = aItem;
    itemTypeString = aItem.itemType; 
    //[self playSound:getSound];
    [APPDEL playSystemSound:@"s_yougotit"  fileType:@"mp3"]; 
    shakeEnable = FALSE;
    MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
    
	NSLog(@"!!! getItem:%@",aItem.itemType);
    
	if([aItem.itemType isEqualToString:I_START]){
        //시작 아이템 획득
		MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                selectWithPK:aItem.missionID
                                                playerID:[APPDEL gUserID] itemID:aItem.itemID];
		
		missionItemInPlay.endYN = (NSMutableString *)@"Y";
		missionItemInPlay.endTime = [NSDate date];
		[missionItemInPlayDao save:missionItemInPlay];
		[caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.itemID]];
		
		MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc]init] autorelease];
		MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:aItem.missionID
                                                             playerID:[APPDEL gUserID]];
		missionInPlay.startYN = (NSMutableString *)@"Y";
		missionInPlay.startTime = [NSDate date];
		[missionInPlayDao save:missionInPlay];
		
		caller.missionStarted = YES;
        [caller uploadMissionPlay:missionInPlay tran:@"c_mission_play_start"];
		caller.missionStartTime = missionInPlay.startTime;
		
		//[self  playSound:winSomethingSound];
        [APPDEL playSystemSound:@"s_winsomething"  fileType:@"wav"]; 
        //[APPDEL playSystemSound:@"game_finish"  fileType:@"mp3"]; 
        
        if ([caller.missionAnswer length] > 0)
        {   
            //미션 퀴즈 있을경우
            [self itemGetAlert:0 Title:nil Message: caller.missionQuiz];
        }
        else 
        {
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"obtain_success", nil),
                               [[APPDEL itemType] valueForKey:aItem.itemType ]];
            
            if ([aItem.info length] < 1) {
                [self itemGetAlert:7 Title:title Message: NSLocalizedString(@"obtain_start_message", nil)];
                
            }else {
                [self itemGetAlert:7 Title:title Message:aItem.info];
            }
        }
		//[self mapInfoUpdate:FALSE];
	}
	else if([aItem.itemType isEqualToString:I_END]){
		//종료 아이템 획득
        //미션 퀴즈가 있을경우
        if ([caller.missionAnswer length] > 0)
        {    
            [self playQuiz:aItem];
        }
        else {
            [self missionSuccess:aItem];
        }
        
	}
	else if([aItem.itemType isEqualToString:I_TIMEOUT_S]){
        //타임 아웃 스타트
        
		caller.timeOutStartTime = [NSDate date];
		caller.timeOutLimitTime = aItem.effectiveTime;
        caller.isTimeOutS = aItem.itemID;
        caller.isTimeOutE = aItem.relationItemID;
        
        caller.RunPassTime = [APPDEL sec2timeFormat:caller.timeOutLimitTime];
        
        for (int i =0; i < [caller._tclockTickers count]; i++) {
            SBTickerView *tickView = [caller._tclockTickers objectAtIndex:i];
            [tickView setFrontView:[SBTickView tickViewWithTitle:[caller.RunPassTime substringWithRange:NSMakeRange(i, 1)] fontSize:24. backColor:RGBA(255, 000, 051, 1)]];
        }    
        [caller.playTimeView setHidden:TRUE];
        
        [self itemGetAlert:1 Title:nil Message:nil];
		
        
        [APPDEL playSystemSound:@"s_gogogo"  fileType:@"mp3"]; 
		//[self performSelector:@selector(onMapView:) withObject:nil afterDelay:1.0]; 
        
	}
	else if([aItem.itemType isEqualToString:I_TIMEOUT_E]){
		
		
		if (caller.isTimeOutS ==  0)
        {    
            [self itemGetAlert:2 Title:nil Message:nil];
            
            //[self performSelector:@selector(onMapView:) withObject:nil afterDelay:1.0]; 	
			return;
            
        }
		if(aItem.relationItemID != caller.isTimeOutS) {
            [self itemGetAlert:3 Title:nil Message:nil];
            
            //[self performSelector:@selector(onMapView:) withObject:nil afterDelay:1.0]; 	
			return;
		}
        
		MissionItemInPlay *relatedItemInPlay = [missionItemInPlayDao 
                                                selectWithPK:aItem.missionID
                                                playerID:[APPDEL gUserID] itemID:aItem.relationItemID];
		
        
		
		[caller.timeOutView setHidden:TRUE];
        
        NSDate *curDate = [NSDate date];
		NSTimeInterval interval = [curDate timeIntervalSinceDate:caller.timeOutStartTime];
        
        
		if(caller.timeOutLimitTime < interval) {	
            // 시간 초과된 경우									
            
            [self itemGetAlert:4 Title:nil Message:[NSString stringWithFormat:@"%@ %d%@",
                                                    NSLocalizedString(@"obtain_fail_message_2", nil),
                                                    (interval-caller.timeOutLimitTime),NSLocalizedString(@"obtain_fail_message_3", nil)]];					
			return;
		}
        caller.timeOutLimitTime = 0;
   		caller.timeOutStartTime = nil;
        
		// timeout 시작 아이템 획득 저장
		relatedItemInPlay.endYN = (NSMutableString *)@"Y";
        relatedItemInPlay.endTime = [NSDate date];
        [missionItemInPlayDao save:relatedItemInPlay];
		[caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.relationItemID]];
		
        
        // timeout 종료 아이템 획득 저장
        MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                selectWithPK:aItem.missionID
                                                playerID:[APPDEL gUserID] itemID:aItem.itemID];
        
		missionItemInPlay.endYN = (NSMutableString *)@"Y";
		missionItemInPlay.endTime = [NSDate date];
		[missionItemInPlayDao save:missionItemInPlay];
		[caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.itemID]];
        caller.isTimeOutS = 0;
        caller.isTimeOutE = 0;
        [caller.playTimeView setHidden:NO];
        
        [APPDEL playSystemSound:@"s_winsometing"  fileType:@"wav"]; 
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"obtain_success", nil),
                           [[APPDEL itemType] valueForKey:aItem.itemType ]];
        
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"obtain_run_record", nil),
                             [APPDEL sec2timeFormat:interval]];
        
        [self itemGetAlert:7 Title:title Message:message];
		//[self mapInfoUpdate:FALSE];
        
	}
    else if([aItem.itemType isEqualToString:I_QUIZ]) {
        [self playQuiz:aItem];
	}
    else if([aItem.itemType isEqualToString:I_SIMPLE]) {
        //힌트아이템    
        
		if(aItem.itemGame != 0)
		{
            [self playGame:aItem];
		}
		else {
			MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                    selectWithPK:aItem.missionID
                                                    playerID:[APPDEL gUserID] itemID:aItem.itemID];
			
			missionItemInPlay.endYN = (NSMutableString *)@"Y";
			missionItemInPlay.endTime = [NSDate date];
			[missionItemInPlayDao save:missionItemInPlay];
			
			[caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.itemID]];
            
            NSString *msg;
            if ([aItem.info length] < 1) {
                msg = NSLocalizedString(@"obtain_no_hint", nil);
            }else {
                msg = aItem.info;
            }
            
            [caller.hints addObject:msg];
            
            [self itemGetAlert:6 Title:nil Message:msg];
            
            //[self mapInfoUpdate:FALSE];
		}
		
	}
	else if([aItem.itemType isEqualToString:I_RADAR_AR] ||
            [aItem.itemType isEqualToString:I_RADAR_MAP] ||
            [aItem.itemType isEqualToString:I_RADAR_ALL] ||
            [aItem.itemType isEqualToString:I_RADAR_MINE] ||
            [aItem.itemType isEqualToString:I_SOLUTION] ||
            [aItem.itemType isEqualToString:I_MINE_NOBOMB])
        
	{
		if (aItem.itemGame != 0) {
            [self playGame:aItem];
		}
		else {
			MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                    selectWithPK:aItem.missionID
                                                    playerID:[APPDEL gUserID] itemID:aItem.itemID];
			
			missionItemInPlay.endYN = (NSMutableString *)@"Y";
			missionItemInPlay.endTime = [NSDate date];
			[missionItemInPlayDao save:missionItemInPlay];
			
			ItemRnPInPlayDao *itemRnPInPlayDao = [[[ItemRnPInPlayDao alloc] init] autorelease];
            ItemRnPInPlay *itemRnPInPlay = [[[ItemRnPInPlay alloc] init] autorelease];
            
            int  cnt = [[caller.dicRnPTaken valueForKey:aItem.itemType] intValue];
            if (cnt > 0) {
                itemRnPInPlay = [itemRnPInPlayDao selectWithPK:aItem.missionID 
                                                      playerID:[APPDEL gUserID] itemType:aItem.itemType];
                itemRnPInPlay.ableCnt++; 
            }
            else {
                itemRnPInPlay.missionID = aItem.missionID;
                itemRnPInPlay.playerID = (NSMutableString *)[APPDEL gUserID];
                itemRnPInPlay.itemType = aItem.itemType;
                itemRnPInPlay.ableTime = [NSDate date];
                itemRnPInPlay.acquiredTime =[NSDate date];
                itemRnPInPlay.ableCnt = 1;
            }
            
            [itemRnPInPlayDao save:itemRnPInPlay];
            
			[caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.itemID]];
            caller.dicRnPTaken = [itemRnPInPlayDao selectDicAt:aItem.missionID 
                                                      playerID:[APPDEL gUserID]];
            //[itemRnPInPlay release];
            
            
            
            if ([aItem.itemType isEqualToString:I_SOLUTION]) 
            {
                [self itemGetAlert:5 Title:nil Message:nil];
            }
            else
            {   
                NSString *msg;
                if ([aItem.info length] < 1) {
                    if ([aItem.itemType isEqualToString:I_RADAR_AR]){
                        msg = NSLocalizedString(@"obtain_radar_ar", nil);
                    }
                    else if ([aItem.itemType isEqualToString:I_RADAR_MAP]){
                        msg = NSLocalizedString(@"obtain_radar_map", nil);
                    }
                    else if ([aItem.itemType isEqualToString:I_RADAR_MINE]){
                        msg = NSLocalizedString(@"obtain_radar_mine", nil);
                    }
                    else if ([aItem.itemType isEqualToString:I_MINE_NOBOMB]){
                        msg = NSLocalizedString(@"obtain_mine_nobomb", nil);
                    }
                }
                else {
                    msg = aItem.info;
                }
                
                NSString *title = [NSString stringWithFormat:NSLocalizedString(@"obtain_success", nil),
                                   [[APPDEL itemType] valueForKey:aItem.itemType ]];
                
                [self itemGetAlert:7 Title:title Message:msg];

            }	
            
			
		}
		
	}
	else if([aItem.itemType isEqualToString:I_MINE]) {
        [caller mineBlast:aItem];
        shakeEnable = TRUE;
        [self mapInfoUpdate:FALSE];
    }
    else if ([aItem.itemType isEqualToString:I_BLACK]){
		// Just skip
	}
	else if([aItem.itemType isEqualToString:I_RANDOM]){
        
        //랜덤획득으로 수정
		MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                selectWithPK:aItem.missionID
                                                playerID:[APPDEL gUserID] itemID:aItem.itemID];
		
		missionItemInPlay.endYN = (NSMutableString *)@"Y";
		missionItemInPlay.endTime = [NSDate date];
		[missionItemInPlayDao save:missionItemInPlay];
        [caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",aItem.itemID]];
        
        //랜덤 아이템 가져오기
        self.randItems = [missionItemInPlayDao selectRand:aItem.missionID 
                                                 playerID:[APPDEL gUserID]];
        //퀴즈등도 복사
        for (AnnoItem *_annoItem in caller.mapAnnotations) {
            for (MissionItem *randItem in [[self.randItems copy] autorelease]) {
                if (_annoItem.missionItem.itemID == randItem.itemID) {
                    if (caller.isTimeOutS > 0 && [randItem.itemType isEqualToString:I_TIMEOUT_S]) {
                        //Run Start 먹었으면 제외
                        [self.randItems removeObject:randItem];
                    }
                    else {
                        [self.randItems removeObject:randItem];
                        [self.randItems addObject:_annoItem.missionItem];
                    }
                    
                }
            }
        }
        [self itemGetAlert:8 Title:nil Message:nil];
    }
}

#pragma mark -
#pragma mark AlerView Functions

-(void)randomFailAlert:(NSString *)msg
{
    [SVProgressHUD dismiss];
    [self itemGetAlert:9 Title:nil Message:nil];
}

- (void)itemGetAlert:(int)itemKind Title:(NSString *)title Message:(NSString *)message {
    
    // 0 .start 1.time start 2. time out end1 3.time out end2 4.time out end outofTiem
    // 5. solution 6. hint fail 7.obtian else 8. random success 9.random fail,11.run end
    
    NSString *titleString;
    NSString *messageString;
    //랜덤 아이템 89
    
    NSArray *titleArray = [[NSArray alloc] initWithObjects:NSLocalizedString(@"mission_quiz", nil),
                           NSLocalizedString(@"obtain_run_start", nil),
                           NSLocalizedString(@"obtain_fail", nil),
                           NSLocalizedString(@"obtain_fail", nil),
                           NSLocalizedString(@"obtain_fail", nil),
                           NSLocalizedString(@"obtain_correct", nil),
                           NSLocalizedString(@"obtain_hint", nil),
                           @"",
                           NSLocalizedString(@"obtain_random_success", nil),
                           NSLocalizedString(@"obtain_random_fail", nil),
                           NSLocalizedString(@"save_success", nil),
                           nil];
    
    NSArray *messageArray = [[NSArray alloc] initWithObjects:@"", 
                             NSLocalizedString(@"obtain_run_start_info", nil),
                             NSLocalizedString(@"obtain_fail_message_0", nil),
                             NSLocalizedString(@"obtain_fail_message_1", nil),
                             @"",
                             NSLocalizedString(@"obtain_correct_message", nil),
                             @"",
                             @"",
                             NSLocalizedString(@"obtain_random_success_message", nil),
                             NSLocalizedString(@"obtain_random_fail_message", nil),
                             NSLocalizedString(@"save_success_message", nil),
                             nil];
    
    if(title == nil){
        titleString = [titleArray objectAtIndex:itemKind];
    }else{
        titleString = title;
    }
    
    if(message == nil){
        messageString = [messageArray objectAtIndex:itemKind];
    }else{
        messageString = message;
    }
    
    NSString *type;
    if(![self stringIsEmpty:itemTypeString]){
        type = [APPDEL itemARFile:itemTypeString];
    }else{
        type = @"";
    }
    
    noticAlertView = [[NoticAlertView alloc] initWithTitle:titleString
                                                   message:messageString
                                                    cancel:NSLocalizedString(@"ok", nil) 
                                                        ok:nil
                                                  itemType:type];
    noticAlertView.tag = 100+itemKind;
    
    [noticAlertView setDelegate:self];
    [noticAlertView show];
    [noticAlertView release];
    noticAlertView = nil;
    [titleArray release];
    [messageArray release];
    itemTypeString = nil;
}


- (BOOL) stringIsEmpty:(NSString *) aString {
    
    if ((NSNull *) aString == [NSNull null]) {
        return YES;
    }
    
    if (aString == nil) {
        return YES;
    } else if ([aString length] == 0) {
        return YES;
    } else {
        aString = [aString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([aString length] == 0) {
            return YES;
        }
    }
    
    return NO;  
}



- (void)playGame:(MissionItem *)aItem
{
    
    gamePlayAlert =  [[GamePlayAlert alloc] initWithItem:aItem 
                                                GameType:0 
                                               GameLevel:aItem.itemGame];
    [gamePlayAlert setDelegate:self];
    [gamePlayAlert show];
    [gamePlayAlert release];
    gamePlayAlert = nil;
    
}

- (void)playQuiz :(MissionItem *)aItem
{
    
    quizAlert =  [[QuizPlayAlert alloc] initWithItem:aItem 
                                                cell:self];
    quizAlert.tag = 0;
    [quizAlert setDelegate:self];
	[quizAlert show];
    [quizAlert release];
    quizAlert = nil;
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    // buttonIndex 4: getItem 에서 호출 나머지는 퀴즈나 게임에서 
    if(buttonIndex == 0){
        [self mapInfoUpdate:FALSE];
    }else if(buttonIndex == 1){
        [self missionSuccess:outstandingItem];
    } else if(buttonIndex ==2){
        [self performSelector:@selector(onMapView:) withObject:nil afterDelay:1.0]; 
    } else if(buttonIndex ==3){
        outstandingItem.itemGame = 0;
        [self getItem:outstandingItem];
        
    } else if(buttonIndex == 4){
        if(alertView.tag == 108) {
            //랜덤 아이템 획득
            [SVProgressHUD showWithStatus:@"Gambling..."];
            int cnt = [self.randItems count];
            if (cnt > 0) {
                int ix = arc4random() % cnt;
                MissionItem *randItem = [self.randItems objectAtIndex:ix];
                
                [self performSelector:@selector(getItem:) withObject:randItem afterDelay:3.0f]; 
            }else {
                [self performSelector:@selector(randomFailAlert:) withObject:nil afterDelay:3.0f]; 
            }
            
        } else {
            [self mapInfoUpdate:FALSE];
            
        }
        
    }
    shakeEnable = TRUE;
}

#pragma mark -
#pragma mark Animation Functions

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    NSLog(@"drawLayer");
    //CGColorRef bgColor = [UIColor colorWithHue:0.6 saturation:1.0 brightness:1.0 alpha:1.0].CGColor;
    //CGContextSetFillColorWithColor(context, bgColor);
    //NSLog(@"drawLayer terpanggil");
    
    
    CGContextSetLineWidth(context, 2.0);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {0.0, 0.8, 0.0, 1.0};
    CGColorRef color = CGColorCreate(colorspace, components);
    CGContextSetStrokeColorWithColor(context, color);
    
    //CGMutablePathRef path = CGPathCreateMutable();
    //CGPathAddArc(path, NULL, self.view.center.x, self.view.center.y, 160, 0, 30*M_PI/180, 0);
    //CGPathAddLineToPoint(path, NULL, <#CGFloat x#>, <#CGFloat y#>)
    
    CGRect rects = CGRectMake(160, 160, 320, 320);
    
    CGColorRef greenColor = [UIColor colorWithRed:1.0 green:1.0 
                                             blue:1.0 alpha:0.1].CGColor; 
    CGColorRef blackColor = [UIColor colorWithRed:0.0 green:0.0 
                                             blue:0.0 alpha:1.0].CGColor;
    
    //drawLinearGradient(context, rects, greenColor, blackColor);
    
    
    CGContextMoveToPoint(context, 160, 160);
    CGContextAddLineToPoint(context, 320, 160);
    CGContextAddArc(context, 160,160, 160, 0, 30*M_PI/180, 0);
    //CGContextAddLineToPoint(context, self.view.center.x, self.view.center.y);
    //CGContextAddLineToPoint(context, 160 ,160);
    CGContextStrokePath(context);
    
    
    NSArray *colors = [NSArray arrayWithObjects:(id)greenColor, (id)blackColor, nil];
    CGFloat locations[] = { 0.0, 1.0 };
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorspace, 
                                                        (CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rects), CGRectGetMinY(rects));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rects), CGRectGetMaxY(rects));
    
    CGContextSaveGState(context);
    //CGContextAddRect(context, rect);
    //CGContextAddEllipseInRect(context, rect);
    
    //draw the path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL,  160, 160, 160, 0, 30*M_PI/180, 0);
    CGPathAddLineToPoint(path, NULL, 160, 160);
    CGPathAddLineToPoint(path, NULL, 320, 160);
    CGContextAddPath(context, path);
    CGPathRelease(path);
    
   
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    
    
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
}

void drawMovingGradient(CGContextRef context, CGRect rect, CGColorRef startColor, 
                        CGColorRef  endColor) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, 
                                                        (CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextSaveGState(context);
    //CGContextAddRect(context, rect);
    //CGContextAddEllipseInRect(context, rect);
    
    
    
    
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    
    
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace); 
}


- (void)randAni {
    
    CALayer *movingLayer =[CALayer layer];
    movingLayer.delegate=self;
    //movingLayer.backgroundColor=[UIColor redColor].CGColor;
    
    
    movingLayer.frame=CGRectMake(self.view.center.x-160, self.view.center.y-150, 320, 320);
    //movingLayer.frame=self.view.frame;
    
    [self.view.layer addSublayer:movingLayer];
    [movingLayer setNeedsDisplay];
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath: @"transform"];
    CATransform3D transform = CATransform3DMakeRotation (180*M_PI/180, 0, 0, 1);
    animation.toValue = [NSValue valueWithCATransform3D: transform];
    animation.duration = 2.0 ;
    animation.cumulative = YES;
    animation.repeatCount = 10000;
    animation.removedOnCompletion = YES;
    [movingLayer addAnimation:animation forKey:@"transform"];
    
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    fadeOutAnimation.toValue = [NSNumber numberWithFloat:0.0];
    
    fadeOutAnimation.duration = 2.0;
    fadeOutAnimation.cumulative = NO;
    fadeOutAnimation.repeatCount = 10000;
    fadeOutAnimation.removedOnCompletion = YES;
    [movingLayer addAnimation:fadeOutAnimation forKey:@"opacity"];
    
    movingLayer.shouldRasterize=YES;
	[self performSelector:@selector(removeAni:) withObject:movingLayer afterDelay:4.0];
}

- (void)removeAni:(id) sender
{
    [(CALayer *)sender removeAllAnimations];
    [(CALayer *)sender removeFromSuperlayer];
}



- (void)didReceiveFinished:(NSString *)result
{
    if ([[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@"SUCCESS"]) {
        
        [self itemGetAlert:10 Title:nil Message:nil];  
    }
}

#pragma mark -
#pragma mark mapview Functions

- (void)mapInfoUpdate:(BOOL) isMissionEnd
{
    [caller InfoUpdate];
	caller.isMissionEnd = isMissionEnd;
    [self performSelector:@selector(onMapView:) withObject:nil afterDelay:1.0]; 	
}



- (void)onMapView:(id)sender
{
    
    [self stopTimer];
    //	[[APPDEL locationManager] stopUpdatingLocation];
    //	[[APPDEL locationManager] stopUpdatingHeading];
    self.accelerometerManager.delegate = nil;
    self.accelerometerManager = nil;
    [self.cameraController dismissModalViewControllerAnimated:NO];
    
    [self.navigationController popViewControllerAnimated:NO];
	NSLog(@"ARGeoViewController:onMapView:stopUpdatingLocation");
}


- (BOOL)viewportContainsCoordinate:(ARCoordinate *)coordinate {
    
	MissionItem *item = coordinate.annoItem.missionItem;
	if (coordinate.radialDistance > item.rangeAR) return NO;
	if([[caller.dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",item.itemID]] isEqualToString:@"Y"]) return NO;
	
	if(([item.itemType isEqualToString:I_START] == NO) &&
       ([item.itemType isEqualToString:I_END] == NO) && 
       (caller.missionStarted == NO)) {
		return NO;
	}
	
	if([item.itemType isEqualToString:I_BLACK]){
        return NO;
    }
    
    if([item.itemType isEqualToString:I_MINE]){ //지뢰
        if (coordinate.radialDistance <= item.rangeAR) {
           // AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
            [caller mineBlast:item];
            [self mapInfoUpdate:false];
        }
        
        
	}
	
	
	double centerAzimuth = self.centerCoordinate.azimuth;
	double leftAzimuth = centerAzimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	double rightAzimuth = centerAzimuth + VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (rightAzimuth > 2 * M_PI) {
		rightAzimuth = rightAzimuth - 2 * M_PI;
	}
	
	BOOL result = (coordinate.azimuth > leftAzimuth && coordinate.azimuth < rightAzimuth);
	
	if(leftAzimuth > rightAzimuth) {
		result = (coordinate.azimuth < rightAzimuth || coordinate.azimuth > leftAzimuth);
	}
	
	double centerInclination = self.centerCoordinate.inclination;
	double bottomInclination = centerInclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	double topInclination = centerInclination + VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	//check the height.
	result = result && (coordinate.inclination > bottomInclination && coordinate.inclination < topInclination);
	
	//NSLog(@"coordinate: %@ result: %@", coordinate, result?@"YES":@"NO");
	
	return result;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)startListening {
	
    
	if (!self.accelerometerManager) {
		self.accelerometerManager = [UIAccelerometer sharedAccelerometer];
		self.accelerometerManager.updateInterval = 0.25;
		self.accelerometerManager.delegate = self;
	}
	
	if (!self.centerCoordinate) {
		self.centerCoordinate = [ARCoordinate coordinateWithRadialDistance:1 inclination:0 azimuth:0];
	}
}

- (CGPoint)pointInView:(UIView *)realityView forCoordinate:(ARCoordinate *)coordinate {
	
	CGPoint point;
	
	//x coordinate.
	
	double pointAzimuth = coordinate.azimuth;
	
	//our x numbers are left based.
	double leftAzimuth = self.centerCoordinate.azimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	if (pointAzimuth < leftAzimuth) {
		//it's past the 0 point.
		point.x = ((2 * M_PI - leftAzimuth + pointAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	} else {
		point.x = ((pointAzimuth - leftAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	}
	
	//y coordinate.
	
	double pointInclination = coordinate.inclination;
	
	double topInclination = self.centerCoordinate.inclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	point.y = realityView.frame.size.height - ((pointInclination - topInclination) / VIEWPORT_HEIGHT_RADIANS) * realityView.frame.size.height;
	
	return point;
}

#define kFilteringFactor 0.05
UIAccelerationValue rollingX, rollingZ;

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	// -1 face down.
	// 1 face up.
	
	//update the center coordinate.
	
	//NSLog(@"x: %f y: %f z: %f", acceleration.x, acceleration.y, acceleration.z);
	
	//this should be different based on orientation.
	
    if (shakeEnable == FALSE) {
        return;
    }
    
	rollingZ  = (acceleration.z * kFilteringFactor) + (rollingZ  * (1.0 - kFilteringFactor));
	rollingX = (acceleration.y * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
	
	if (rollingZ > 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) + M_PI / 2.0;
	} else if (rollingZ < 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) - M_PI / 2.0;// + M_PI;
	} else if (rollingX < 0) {
		self.centerCoordinate.inclination = M_PI/2.0;
	} else if (rollingX >= 0) {
		self.centerCoordinate.inclination = 3 * M_PI/2.0;
	}
	
    static int shakeCount = 0;
    static NSDate *shakeStart = nil;
    
    NSDate *now = [[NSDate alloc] init];
    NSDate *checkDate = [[NSDate alloc] initWithTimeInterval:1.5f sinceDate:shakeStart];
    
    if([now compare:checkDate] == NSOrderedDescending || shakeCount == 0)
    {
        shakeCount = 0;
        [shakeStart release];
        shakeStart = [[NSDate alloc] init];
    }
    
    [now release];
    [checkDate release];
    
    
    if(fabsf(acceleration.x) > 1.4 || fabsf(acceleration.y) > 1.4 || fabsf(acceleration.z) > 1.4)
    {
        NSLog(@"shakeCount:%d",shakeCount);
        NSLog(@"acceleration.x:%f,acceleration.y:%f,acceleration.z:%f",acceleration.x,acceleration.y,acceleration.z);
        shakeCount++;
        if(shakeCount > 0)
        {
            NSLog(@"Fired! shakeCount:%d",shakeCount);
            [self getItemAnimation];
            shakeCount = 0;
            [shakeStart release];
            shakeStart = [[NSDate alloc] init];
        }
    }
	
	if (self.accelerometerDelegate && [self.accelerometerDelegate respondsToSelector:@selector(accelerometer:didAccelerate:)]) {
		//forward the acceleromter.
		[self.accelerometerDelegate accelerometer:accelerometer didAccelerate:acceleration];
	}
    
    
}

NSComparisonResult LocationSortClosestFirst(ARCoordinate *s1, ARCoordinate *s2, void *ignore) 
{
	if (s1.radialDistance < s2.radialDistance) {
		return NSOrderedAscending;
	} else if (s1.radialDistance > s2.radialDistance) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}

- (void)addCoordinate:(ARCoordinate *)coordinate {
	[self addCoordinate:coordinate animated:YES];
}

- (void)addCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated {
	//do some kind of animation?
	[ar_coordinates addObject:coordinate];
	
	if (coordinate.radialDistance > self.maximumScaleDistance) {
		self.maximumScaleDistance = coordinate.radialDistance;
	}
	
	//message the delegate.
	[ar_coordinateViews addObject:[self.delegate viewForCoordinate:coordinate]];
}

- (void)addCoordinates:(NSArray *)newCoordinates {
	
	//go through and add each coordinate.
	for (ARCoordinate *coordinate in newCoordinates) {
		[self addCoordinate:coordinate animated:NO];
	}
}

- (void)removeCoordinate:(ARCoordinate *)coordinate {
	[self removeCoordinate:coordinate animated:YES];
}

- (void)removeCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated {
	//do some kind of animation?
	[ar_coordinates removeObject:coordinate];
}

- (void)removeCoordinates:(NSArray *)coordinates {	
	for (ARCoordinate *coordinateToRemove in coordinates) {
		NSUInteger indexToRemove = [ar_coordinates indexOfObject:coordinateToRemove];
		
		//TODO: Error checking in here.
		
		[ar_coordinates removeObjectAtIndex:indexToRemove];
		[ar_coordinateViews removeObjectAtIndex:indexToRemove];
	}
}

#pragma mark -
#pragma mark Timer

- (void)startTimer{
    /*
    if (!_updateTimer) {
        [_updateTimer invalidate];
		_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                         target:self
                                                       selector:@selector(updateLocations:)
                                                       userInfo:nil
                                                        repeats:YES] retain];
	}
     */
    
}


- (void)stopTimer{
    /*
    if(_updateTimer != nil) {
		[_updateTimer invalidate];
		_updateTimer = nil;
	}
     */
}

//- (void)updateLocations:(NSTimer *)timer {

- (void)updateLocations {
	
	if (!ar_coordinateViews || ar_coordinateViews.count == 0) {
		return;
	}
	
	//ar_debugView.text = [self.centerCoordinate description];
	//NSLog(@"updateL%f,%f,%f",self.centerCoordinate.azimuth,self.centerCoordinate.radialDistance,self.centerCoordinate.inclination);	
	minDistItem.radialDistance = 9999999;
	minDistItem.azimuth = 0;
	minDistItem.title = nil;
	minDistItem.annoItem = nil;
	
	minDistItemInView.radialDistance = 9999999;
	minDistItemInView.azimuth = 0;
	minDistItemInView.title = nil;
	minDistItemInView.annoItem = nil;
	int index = 0;
	for (ARCoordinate *coordinate in ar_coordinates) {
		if(([coordinate.annoItem.missionItem.itemType isEqualToString:I_START] == NO) &&
           ([coordinate.annoItem.missionItem.itemType isEqualToString:I_END] == NO) && 
           (caller.missionStarted == NO)) {
			continue;
		}
        
		if (minDistItem.radialDistance > coordinate.radialDistance &&
            [[caller.dicItemEnd valueForKey:[NSString stringWithFormat:@"%d",coordinate.annoItem.missionItem.itemID]] isEqualToString:@"Y"] == NO &&
            [coordinate.annoItem.missionItem.itemType isEqualToString:I_MINE] == NO &&
            [coordinate.annoItem.missionItem.itemType isEqualToString:I_BLACK] == NO) {
            
            
            if(caller.missionStarted == YES)
            {     
                /*
                 //아이템이 ALL 투명이거나 AR 투명일경우 AR 레이더, all 레이더 없을경우 skip
                 if (([coordinate.annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] || 
                 [coordinate.annoItem.missionItem.showType isEqualToString:SHOW_MAP]) &&
                 ([caller.dicRnPTaken valueForKey:I_RADAR_AR] == nil &&
                 [caller.dicRnPTaken valueForKey:I_RADAR_ALL] == nil )) 
                 {
                 continue;
                 }
                 */
                if ([coordinate.annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_S] &&
                    caller.isTimeOutS > 0)
                {
                    continue;
                }
                if ([coordinate.annoItem.missionItem.itemType isEqualToString:I_END] && [caller.mandatory.text intValue] > 1)
                {
                    continue;
                }
                
                minDistItem.radialDistance = coordinate.radialDistance;
                minDistItem.azimuth = coordinate.azimuth;
                minDistItem.title = coordinate.title;
                minDistItem.annoItem = coordinate.annoItem;
                
            }
            else if ([coordinate.annoItem.missionItem.itemType isEqualToString:I_START] == YES )
            {
                minDistItem.radialDistance = coordinate.radialDistance;
                minDistItem.azimuth = coordinate.azimuth;
                minDistItem.title = coordinate.title;
                minDistItem.annoItem = coordinate.annoItem;
            }
           // NSLog(@"%@ : %.0fm",minDistItem.title, minDistItem.radialDistance);
		}
	}
	
	for (ARCoordinate *coordinate in ar_coordinates) {
		
		UIView *viewToDraw = [ar_coordinateViews objectAtIndex:index];
		
		if ([self viewportContainsCoordinate:coordinate]) {
			if (minDistItem.annoItem == coordinate.annoItem) {
				if (minDistItemInView.radialDistance > coordinate.radialDistance) {
					minDistItemInView.radialDistance = coordinate.radialDistance;
					minDistItemInView.azimuth = coordinate.azimuth;
					minDistItemInView.title = coordinate.title;
					minDistItemInView.annoItem = coordinate.annoItem;
				}
				CGPoint loc = [self pointInView:ar_overlayView forCoordinate:coordinate];
				
				CGFloat scaleFactor = 1.0;
				if (self.scaleViewsBasedOnDistance) {
					scaleFactor = 1.0 - self.minimumScaleFactor * (coordinate.radialDistance / self.maximumScaleDistance);
				}
				
				float width = viewToDraw.bounds.size.width * scaleFactor;
				float height = viewToDraw.bounds.size.height * scaleFactor;
				
				viewToDraw.frame = CGRectMake(loc.x - width / 2.0, loc.y - height / 2.0, width, height);
				
				CATransform3D transform = CATransform3DIdentity;
				
				//set the scale if it needs it.
				if (self.scaleViewsBasedOnDistance) {
					//scale the perspective transform if we have one.
					transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);
				}
				
				if (self.rotateViewsBasedOnPerspective) {
					transform.m34 = 1.0 / 300.0;
					
					double itemAzimuth = coordinate.azimuth;
					double centerAzimuth = self.centerCoordinate.azimuth;
					if (itemAzimuth - centerAzimuth > M_PI) centerAzimuth += 2*M_PI;
					if (itemAzimuth - centerAzimuth < -M_PI) itemAzimuth += 2*M_PI;
					
					double angleDifference = itemAzimuth - centerAzimuth;
					transform = CATransform3DRotate(transform, self.maximumRotationAngle * 
                                                    angleDifference / (VIEWPORT_HEIGHT_RADIANS / 2.0) , 0, 1, 0);
				}
				
				viewToDraw.layer.transform = transform;
				
				//if we don't have a superview, set it up.
				if (!(viewToDraw.superview)) {
					[ar_overlayView addSubview:viewToDraw];
					[ar_overlayView sendSubviewToBack:viewToDraw];
				}
				
				self.imgItemView = viewToDraw;
				
			} else {
				[viewToDraw removeFromSuperview];
				viewToDraw.transform = CGAffineTransformIdentity;
			}
		} else {
			[viewToDraw removeFromSuperview];
			viewToDraw.transform = CGAffineTransformIdentity;
		}
		index++;
	}
	
	if (minDistItem.radialDistance == 9999999.0) {
		[ar_infoView setTitle:@"" 
                     forState:UIControlStateNormal];
		[ar_infoView1 setTitle:NSLocalizedString(@"mission_completed", nil) 
                      forState:UIControlStateNormal];		
	}
	else {
        
        //아이템이 ALL 투명이거나 AR 투명일경우 AR 레이더, all 레이더 없을경우 
        if (([minDistItem.annoItem.missionItem.showType isEqualToString:SHOW_TRANSPARENT] || 
             [minDistItem.annoItem.missionItem.showType isEqualToString:SHOW_MAP]) &&
            ([caller.dicRnPTaken valueForKey:I_RADAR_AR] == nil &&
             [caller.dicRnPTaken valueForKey:I_RADAR_ALL] == nil )) 
        {
            [ar_infoView setTitle:NSLocalizedString(@"ar_clear1", nil) forState:UIControlStateNormal];
            
            
            [ar_infoView1 setTitle:NSLocalizedString(@"ar_clear2", nil) forState:UIControlStateNormal];
            
            
            [radianItem removeFromSuperview];
            [radianPhone removeFromSuperview];
            
            
        }else {
            [ar_infoView setTitle:[NSString stringWithFormat:@"%@:%.0fm",[[APPDEL itemTypeObjects] objectAtIndex:
                                                                          [[APPDEL itemTypeKeys] indexOfObject:minDistItem.annoItem.missionItem.itemType]],
                                   minDistItem.radialDistance]
                         forState:UIControlStateNormal];
            
            
            [ar_infoView1 setTitle:[NSString stringWithFormat:@"%@:%dm",NSLocalizedString(@"radius_of_visibility", nil),
                                    minDistItem.annoItem.missionItem.rangeAR] 
                          forState:UIControlStateNormal];
            
            [ar_overlayView addSubview:radianPhone];
            [ar_overlayView addSubview:radianItem];
            
        }
		
		
	}
	
	//radianPhone.transform = CGAffineTransformMakeRotation(self.centerCoordinate.azimuth);
	radianItem.transform = CGAffineTransformMakeRotation(minDistItem.azimuth);
}

//- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
//	//[[APPDEL locationManager] stopUpdatingLocation];
//}
//
//- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
//	[[APPDEL locationManager] startUpdatingLocation];
//}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	
	//NSLog(@"newHeading.headingAccuracy:%f",newHeading.headingAccuracy);
	if (newHeading.headingAccuracy < 0.0 || newHeading.headingAccuracy > 30.0) return;
	//if (newHeading.headingAccuracy < 0.0)		return;
	
	// Use the true heading if it is valid.
	CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
                                       newHeading.trueHeading : newHeading.magneticHeading);
	
	rawDirection = theHeading;
    //NSLog(@"rawDirection:%d",rawDirection);

	//	self.centerCoordinate.azimuth = fmod(theHeading, 360.0) * (2 * (M_PI / 360.0));
	//	NSLog(@"didUpdateH%f,%f,%f",self.centerCoordinate.azimuth,self.centerCoordinate.radialDistance,self.centerCoordinate.inclination);	
	
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didUpdateHeading:)]) {
		//forward the call.
		[self.locationDelegate locationManager:manager didUpdateHeading:newHeading];
	}
    [self onSchedule];
}

#define kDirectionFilterFactor 0.05

- (void)onSchedule {
    
	double sub = rawDirection - correctedDirection;
	if (sub < -180) {
		sub += 360;
	}
	if (180 < sub) {
		sub -= 360;
	}
	correctedDirection = sub * kDirectionFilterFactor + correctedDirection;
	if (360 <= correctedDirection) {
		correctedDirection -= 360;
	}
	if (correctedDirection < 0) {
		correctedDirection += 360;
	}
	self.centerCoordinate.azimuth = fmod(correctedDirection, 360.0) * (2 * (M_PI / 360.0));
    
    [self updateLocations];
    //NSLog(@"azimuth:%d",self.centerCoordinate.azimuth);
   // radianPhone.transform = CGAffineTransformMakeRotation(self.centerCoordinate.azimuth);
}


/*
 // 값의 변화를 부드럽게 하기위한 상수
 #define kHeadingFilteringFactor 0.5
 // 값의 변화차이가 심하여 격차가 벌어질경우 허용하는 최대변화량
 #define kMaximumEpsilon 50
 // 값의 변화를 저장할 공간
 double heading;
 
 - (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading 
 {
 // newHeading의 magneticHeading값은 0~360도이다.
 // 만약 newHeading.magneticHeading값의 변화가 빨라서 350도 정도에서 10도 정도로 바뀐다면 부드럽게 바뀌기 위한 basic low-pass filter를 사용하므로
 // heading변수의 값이 350 -> 175 -> 90 -> 45 -> 10 이렇게 바뀌기 때문에 오버레이뷰들이 획 도는 현상이 발생한다.
 // 따라서 값의 변화가 일정이상 차이가 나면 basic low-pass filter를 사용하지 않고 바로 newHeading.magneticHeading의 값을 heading변수에 바로 대입한다.
 
 // 값의 변화가 크다면 그대로 대입한다.
 if (ABS(newHeading.magneticHeading - heading) > kMaximumEpsilon)
 {
 heading = newHeading.magneticHeading;
 }
 // 그렇지 않으면 부드럽게 하기위한 basic low-pass filter를 사용한다.
 else
 {
 heading  = (newHeading.magneticHeading * kHeadingFilteringFactor) + (heading  * (1.0 - kHeadingFilteringFactor));
 }
 
 self.centerCoordinate.azimuth = fmod(heading, 360.0) * (2 * (M_PI / 360.0));
 if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didUpdateHeading:)]) 
 {
 [self.locationDelegate locationManager:manager didUpdateHeading:newHeading];
 }
 }
 */

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)]) {
		//forward the call.
		return [self.locationDelegate locationManagerShouldDisplayHeadingCalibration:manager];
	}
	
	return NO;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
		//forward the call.
		[self.locationDelegate locationManager:manager didUpdateToLocation:newLocation fromLocation:oldLocation];
	}
    [self updateLocations];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
		//forward the call.
		return [self.locationDelegate locationManager:manager didFailWithError:error];
	}
}



@end
