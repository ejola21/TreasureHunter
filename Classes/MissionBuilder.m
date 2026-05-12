//
//  MissionMake.m
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MissionBuilder.h"
#import "Mission.h"
#import "MissionBuilderInfo.h"
#import "MissionBuilderDetail.h"
#import "TreasureHunterAppDelegate.h"
#import "AnnoItem.h"
#import "MissionItemDao.h"
#import "MissionDao.h"
#import "ItemQuizDao.h"
#import "ImageManager.h"



enum
{
	aQuiz = 0,
	aQuiz20
};


@implementation MissionBuilder

@synthesize theMapView,selectedAnno,itemPicker,itemPickerToolbar,mission,lastAnno,lastAnno2;


#pragma mark -         
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	[super viewDidLoad];
	
    indicator_ =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:indicator_];
    
    selectedAnno = [[AnnoItem alloc] init];
    //lastAnno = [[AnnoItem alloc] init];
	
	self.theMapView.delegate = self;
	self.theMapView.tag = 1;
    self.theMapView.showsUserLocation = YES;
    
    
	
    recvCoord = [APPDEL startPoint].coordinate;
    
	[APPDEL locationManager].delegate = self;
    [[APPDEL locationManager] startUpdatingLocation];  
    [[APPDEL locationManager] startUpdatingHeading];  
    
    
	//맵 tap 인식
	UITapGestureRecognizer *recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openItemPicker:)] autorelease];
	recognizer.delegate = self;
	[theMapView addGestureRecognizer:recognizer];
    theMapView.region = MKCoordinateRegionMakeWithDistance([APPDEL locationManager].location.coordinate, 150, 150);
    theMapView.zoomEnabled = YES;
    theMapView.scrollEnabled =YES;
	
    
	//아이템 드레그 인식
	//UIPanGestureRecognizer *dRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(saveItem:)] autorelease];
	//dRecognizer.delegate = self;
	//[theMapView addGestureRecognizer:dRecognizer];
    
    
    
	//////////////////////////////////////////////////////////////////////////////////
	// 네비게이이션 버튼 set
	// create a toolbar to have two buttons in the right
	UIToolbar* tools = [[UIToolbar alloc] initWithFrame:CGRectMake(155.0, 0, 150.0, 44.01)];
	NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:4];
	
	// 현위치
	UIImage *buttonImage = [UIImage imageNamed:@"button_now.png"];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:buttonImage forState:UIControlStateNormal];
	button.frame = CGRectMake(0, 0, 30, 30);	
    
	[button addTarget:self action:@selector(gotoCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
    
	UIBarButtonItem *bi = [[UIBarButtonItem alloc] initWithCustomView:button];
	
	[buttons addObject:bi];
	[bi release];
	
	// 미션 편집
	buttonImage = [UIImage imageNamed:@"button_design.png"];
	button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:buttonImage forState:UIControlStateNormal];
	button.frame = CGRectMake(0, 0, 30, 30);	
	[button addTarget:self action:@selector(showMissionInfo:) forControlEvents:UIControlEventTouchUpInside];
	bi = [[UIBarButtonItem alloc] initWithCustomView:button];
	
	[buttons addObject:bi];
	[bi release];
    
    // 서버 업로드 
    /*
     buttonImage = [UIImage imageNamed:@"button_server_up.png"];
     button = [UIButton buttonWithType:UIButtonTypeCustom];
     [button setImage:buttonImage forState:UIControlStateNormal];
     button.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);	
     [button addTarget:self action:@selector(uploadServer) forControlEvents:UIControlEventTouchUpInside];
     bi = [[UIBarButtonItem alloc] initWithCustomView:button];
     
     [buttons addObject:bi];
     [bi release];
     */
    
	// create a spacer
	bi = [[UIBarButtonItem alloc]
          initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	[buttons addObject:bi];
	[bi release];
	
	// 미션 save 
	bi = [[UIBarButtonItem alloc]
		  initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(editSaveClick)];
	bi.style = UIBarButtonItemStyleBordered;
	[buttons addObject:bi];
	[bi release];
    
	[tools setItems:buttons animated:NO];
	[buttons release];
	[tools setTintColor:[APPDEL backColor]];
    
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:tools] autorelease];
	[tools release];
	
	UIBarButtonItem *eBtnCancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self
                                                                               action:@selector(editCancelClick)];
	/*
     UIBarButtonItem *eBtnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
     target:self
     action:@selector(editSaveClick)];
	 */
	
	//[self.navigationItem setRightBarButtonItem:eBtnDone animated:YES];
	[self.navigationItem setLeftBarButtonItem:eBtnCancel animated:YES];
	
	[eBtnCancel release]; 
	
	
	itemPicker = [[MultiPickerView alloc]initWithFrame:CGRectZero];
    
    CGRect pickerFrame = itemPicker.frame;
	
	pickerFrame.size.width = 320*1.0f;
	pickerFrame.size.height =  162*1.0f;
    
	pickerFrame.origin.x = 0;
	pickerFrame.origin.y = 44;
    
	itemPicker.frame = pickerFrame;  
	
	itemPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	itemPickerToolbar.barStyle = UIBarStyleBlackOpaque;
	[itemPickerToolbar sizeToFit];
	
	UILabel *title = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
	title.text =NSLocalizedString(@"item_message", nil);
	title.alpha = 0.3;
	[itemPickerToolbar addSubview:title];
    
    UILabel *hint = [[[UILabel alloc] initWithFrame:CGRectMake(80, 390, 235, 20)] autorelease];
    hint.backgroundColor = RGBA(051, 051, 051, 0.7);
    hint.text = NSLocalizedString(@"builder_item_hint", nil);
    hint.font = [UIFont systemFontOfSize:14.0];
    hint.textColor = [UIColor whiteColor];
    //hint.alpha = 0.5;
    [theMapView addSubview:hint];
    
    NSString* path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"pickerData.plist"];
    NSMutableDictionary* data = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    self.itemPicker.data = data;
    self.itemPicker.mdelegate = self;
    
    
	NSMutableArray *barItems = [[NSMutableArray alloc]init];
	
	UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					 target:self action:nil];
	[barItems addObject:btnFlexibleSpace];
	[btnFlexibleSpace release];
	
	UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																			  target:self
																			  action:@selector(pickerCancelClick)];
	[barItems addObject:btnCancel];
	[btnCancel release];
	
	UIBarButtonItem *btnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			target:self
																			action:@selector(pickerDoneClick)];
	[barItems addObject:btnDone];
	[btnDone release];
	[itemPickerToolbar setItems:barItems animated:YES];
	[barItems release];
	
	[self overlayRefresh];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
    [[APPDEL locationManager] stopUpdatingLocation];  
    [[APPDEL locationManager] stopUpdatingHeading];  
    [APPDEL locationManager].delegate = nil;
	self.theMapView = nil;
	self.itemPicker = nil;
	self.itemPickerToolbar = nil;
	self.mission = nil;
	self.selectedAnno =nil;
    
	self.lastAnno = nil;
    self.lastAnno2 = nil;
    [indicator_ release];
    [pickerSelection release];
    pickerSelection = nil;  
    
}


- (void)dealloc {
    [[APPDEL locationManager] stopUpdatingLocation];  
    [[APPDEL locationManager] stopUpdatingHeading];  
    [APPDEL locationManager].delegate = nil;
	[theMapView release];
	[itemPicker release];
	[itemPickerToolbar release];
	[mission release];
	[selectedAnno release];
    
	[lastAnno release];
    [lastAnno2 release];
    [indicator_ release];
    [pickerSelection release];
	[super dealloc];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self overlayRefresh];
}


/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

/*
 -(void)openPinView:(UITapGestureRecognizer *)gestureRecognizer
 {
 [self.mapView selectAnnotation:_anno animated:NO];
 }
 */

/*
 #pragma mark -
 #pragma mark locationManager
 
 */
//실패시
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    if (abs(howRecent) < 15.0 )  
    {
        if (newLocation != oldLocation) 
            [APPDEL setStartPoint:newLocation];
    }
}

#pragma mark -
#pragma mark util

- (void)startIndicator {
    if ( UIActivityIndicatorViewStyleWhiteLarge == indicator_.activityIndicatorViewStyle ) {
        indicator_.frame = CGRectMake( 0, 0, 50, 50 );
    } else {
        indicator_.frame = CGRectMake( 0, 0, 20, 20 );
    }
    indicator_.center = self.view.center;
    [indicator_ startAnimating];
	
	
}

- (void)stopIndicator {
    //indicator_.hidesWhenStopped = NO;
    [indicator_ stopAnimating];
}

- (void)isCheck{
    int timeOutCount = 0;
    int startCount = 0;
    int endCount = 0;
    int cnt = [self.mission.mItems count];
    
    for (int i= 0; i < cnt; i++)
    {
        MissionItem *missionItem = [self.mission.mItems objectAtIndex:i];
        
        if ([missionItem.itemType isEqualToString:I_TIMEOUT_S]) {
            
            timeOutCount++;
        }
        
        if ([missionItem.itemType isEqualToString:I_TIMEOUT_E]) 
        {
            timeOutCount--;
        }
        if ([missionItem.itemType isEqualToString:I_END]) 
            endCount++;
        if ([missionItem.itemType isEqualToString:I_START]) 
            startCount++;
    }
    if(startCount == 0){
        [self.itemPicker selectRow:0 inComponent:0 animated:true];
        return;
    }
    if(endCount == 0){
        [self.itemPicker selectRow:1 inComponent:0 animated:true];
        return;
    }
    if(timeOutCount > 0){
        [self.itemPicker selectRow:7 inComponent:0 animated:true];
        return;
    }
    if(timeOutCount < 0){
        [self.itemPicker selectRow:6 inComponent:0 animated:true];
        return;
    }
}

- (BOOL)dataCheck
{
	BOOL ret = YES;
	
	NSString *atitle = nil;
	NSString *message = nil;
	int timeOutScnt = 0;
	int timeOutEcnt = 0;
	int mandatoryCnt = 0;
    int end_cnt = 0;
    int start_cnt = 0;
    int show_clear=0, show_map_cnt = 0, show_ar_cnt = 0,mine_cnt= 0;
    int radar_all =0, radar_map = 0, radar_ar =0,radar_mine  =0;
    int dupcheck = 0;
    
    
    NSMutableArray *timeItimes = [[[NSMutableArray alloc] init] autorelease];
	
	if ([self.mission.mTitle isEqualToString:@""] || self.mission.mTitle == nil )
	{
		atitle = NSLocalizedString(@"data_check_title_0", nil);
		message = NSLocalizedString(@"data_check_message_0", nil);
        
	}
	if ([self.mission.mDescription isEqualToString:@""] || self.mission.mDescription == nil)
	{
        atitle = NSLocalizedString(@"data_check_title_1", nil);
		message = NSLocalizedString(@"data_check_message_1", nil);
        
	}
	if ([self.mission.mPlace isEqualToString:@""] || self.mission.mPlace == nil)
	{
        atitle = NSLocalizedString(@"data_check_title_2", nil);
		message = NSLocalizedString(@"data_check_message_2", nil);
        
	}
	
	int cnt = [self.mission.mItems count];
	
	if (cnt < 3) {
		
		atitle = NSLocalizedString(@"data_check_title_3", nil);
		message = NSLocalizedString(@"data_check_message_3", nil);
	}
	else
	{
		for (int i= 0; i < cnt; i++)
		{
			MissionItem *missionItem = [self.mission.mItems objectAtIndex:i];
			
            if ([missionItem.itemType isEqualToString:I_QUIZ]) {
                
                if ([missionItem.itemQuizzes count] < 1) {
                    atitle = NSLocalizedString(@"data_check_title_12", nil);
                    message = NSLocalizedString(@"data_check_message_12", nil);
                }
                else {
                    for (ItemQuiz *quiz in missionItem.itemQuizzes) {
                        if([quiz.quiz isEqualToString:@""] || quiz.quiz == nil)
                        {
                            atitle = NSLocalizedString(@"data_check_title_12", nil);
                            message = NSLocalizedString(@"data_check_message_12", nil);
                        }
                        
                        if([quiz.answer isEqualToString:@""] || quiz.answer == nil)
                        {
                            atitle = NSLocalizedString(@"data_check_title_13", nil);
                            message = NSLocalizedString(@"data_check_message_13", nil);
                        }
                    } 

                }

            }    
            
			if ([missionItem.itemType isEqualToString:I_TIMEOUT_S]) {
                
                timeOutScnt++;
            }
			if ([missionItem.itemType isEqualToString:I_TIMEOUT_E]) 
			{
                timeOutEcnt++;
                [timeItimes addObject:missionItem];
                
                if (missionItem.effectiveTime < 1) {
                    atitle = NSLocalizedString(@"data_check_title_5", nil);
                    message = NSLocalizedString(@"data_check_message_5", nil);
                }
                
            }
            
            if ([missionItem.showType isEqualToString:SHOW_AR]) {
                show_ar_cnt++;
            }
            if ([missionItem.showType isEqualToString:SHOW_MAP]) 
			{
                show_map_cnt++;
            }
            if ([missionItem.showType isEqualToString:SHOW_TRANSPARENT]) 
			{
                show_clear++;
            }
            if ([missionItem.itemType isEqualToString:I_MINE]) {
                
                mine_cnt++;
            }
            if ([missionItem.itemType isEqualToString:I_RADAR_MINE]) {
                
                radar_mine++;
            }
            if ([missionItem.itemType isEqualToString:I_RADAR_ALL]) {
                
                radar_all++;
            }
            if ([missionItem.itemType isEqualToString:I_RADAR_AR]) {
                
                radar_ar++;
            }
            if ([missionItem.itemType isEqualToString:I_RADAR_MAP]) {
                
                radar_map++;
            }
            
			if (missionItem.mandatory == MANDATORY_Y) mandatoryCnt++;
            
            if ([missionItem.itemType isEqualToString:I_END]) end_cnt++;
            if ([missionItem.itemType isEqualToString:I_START]) start_cnt++;
		}
		// AR 레이더 추가 ???
        
        
        if (show_map_cnt > 0 && radar_ar < 1) {
            atitle = NSLocalizedString(@"data_check_title_14", nil);
            message = NSLocalizedString(@"data_check_message_14", nil);
        }
        if (dupcheck < 0) {
            
            atitle = NSLocalizedString(@"data_check_title_16", nil);
            message = NSLocalizedString(@"data_check_message_16", nil);
        }
    	if (end_cnt == 0)
		{
            atitle = NSLocalizedString(@"data_check_title_8", nil);
            message = NSLocalizedString(@"data_check_message_8", nil);
            
		}
		if (end_cnt > 1)
		{
			atitle = [NSString stringWithFormat:NSLocalizedString(@"data_check_title_9_0", nil),end_cnt];
            message = NSLocalizedString(@"data_check_message_9", nil);
            
		}
		
        if (start_cnt == 0)
		{
            atitle = NSLocalizedString(@"data_check_title_10", nil);
            message = NSLocalizedString(@"data_check_message_10", nil);
            
		}
		if (start_cnt > 1)
		{
            atitle = [NSString stringWithFormat:NSLocalizedString(@"data_check_title_11_0", nil),start_cnt];
            message = NSLocalizedString(@"data_check_message_11", nil);
            
		}
        if (timeOutEcnt > 0) {
            //타임아웃 제한시간 셋팅
            for ( MissionItem *timeItem in timeItimes) {
                for (MissionItem *missionItem  in self.mission.mItems) {
                    if( missionItem.itemID == timeItem.relationItemID)
                    {
                        missionItem.effectiveTime = timeItem.effectiveTime;
                        missionItem.effectiveRange = timeItem.effectiveTime;
                        missionItem.relationItemID = timeItem.itemID;
                        break;
                    }
                    
                }
            }

        }
	}
	
	if(atitle != nil)
	{
		ret = NO;
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:atitle 
                                                             message:message
                                                            delegate:self 
                                                   cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                                   otherButtonTitles:nil] autorelease];
		[alertView show];
	}
  
        
    //타임아웃 제한시간 셋팅
    for ( MissionItem *timeItem in timeItimes) {
        for (MissionItem *missionItem  in self.mission.mItems) {
            if( missionItem.itemID == timeItem.relationItemID)
            {
                missionItem.effectiveTime = timeItem.effectiveTime;
                missionItem.effectiveRange = timeItem.effectiveTime;
                missionItem.relationItemID = timeItem.itemID;
                break;
            }
            
        }
    }
        
  
	return ret;
}

#pragma mark -
#pragma mark pickerView


- (void)selectionChanged:(NSArray*)selections
{

    if (selections != nil) pickerSelection = [selections retain];
    
    for (NSInteger i=0; i<[selections count]; i++) {
        NSDictionary* dict = [selections objectAtIndex:i];
        NSString* selectionText = [NSString stringWithFormat:@"Level%d:  %@ => %@\n",i,[dict objectForKey:@"key"],[dict objectForKey:@"value"]];
        NSLog(@"picker select : %@",selectionText);
    }
    
    
    if (lastAnno.missionItem.latitude == recvCoord.latitude &&	lastAnno.missionItem.longitude == recvCoord.longitude)
	{
		[self.theMapView removeAnnotation:lastAnno];
		[self.mission.mItems removeObject:lastAnno.missionItem];
        
        if ([lastAnno.missionItem.itemType isEqualToString:I_TIMEOUT_S]) {
            [self.theMapView removeAnnotation:lastAnno2];
            [self.mission.mItems removeObject:lastAnno2.missionItem];
        }
        
        if([lastAnno.missionItem.itemType isEqualToString:I_MINE] || [lastAnno.missionItem.itemType isEqualToString:I_BLACK])
        {
            [self overlayRefresh];
        }
        
	}
    

    AnnoItem *_annoItem = [[[AnnoItem alloc] init] autorelease];
    
    
    if (selections != nil) {
        _annoItem.missionItem = [self.mission addMissionItem];
        _annoItem.missionItem.itemType = [[selections objectAtIndex:0] objectForKey:@"key"];
        
        _annoItem.missionItem.showType = [[selections objectAtIndex:1] objectForKey:@"key"];
        _annoItem.missionItem.rangeAR = [[[selections objectAtIndex:2] objectForKey:@"key"] intValue];
        
        if ([[[selections objectAtIndex:0] objectForKey:@"key"] isEqualToString:I_TIMEOUT_S] ) 
        {

            AnnoItem *_annoItem2 = [[[AnnoItem alloc] init] autorelease];

            _annoItem2.missionItem = [self.mission addMissionItem];
            _annoItem2.missionItem.itemType = (NSMutableString *)I_TIMEOUT_E;
            _annoItem2.missionItem.showType = [[selections objectAtIndex:1] objectForKey:@"key"];
            _annoItem2.missionItem.rangeAR = [[[selections objectAtIndex:2] objectForKey:@"key"] intValue];
            _annoItem2.missionItem.mandatory = MANDATORY_Y;
            _annoItem2.missionItem.latitude = recvCoord.latitude+0.0003;
            _annoItem2.missionItem.longitude = recvCoord.longitude+0.0003;
            _annoItem2.missionItem.relationItemID = _annoItem.missionItem.itemID;
           // _annoItem2.missionItem.effectiveTime = 60;
            _annoItem2.missionItem.effectiveRange = 42;
            self.lastAnno2 = _annoItem2;
            
            //Run Start
            _annoItem.missionItem.relationItemID = _annoItem2.missionItem.itemID;
            _annoItem.missionItem.effectiveRange = _annoItem2.missionItem.effectiveRange;
            _annoItem.missionItem.effectiveTime = _annoItem2.missionItem.effectiveTime;
            
            
            [self.theMapView addAnnotation:_annoItem2];
            //[_annoItem2 release];
        }else {
            self.lastAnno2 = nil;
        }
        
    }else {
        _annoItem.missionItem = [self.mission addMissionItem];
        _annoItem.missionItem.itemType = (NSMutableString *)I_START;
        _annoItem.missionItem.showType = (NSMutableString *)SHOW_ALL;
        _annoItem.missionItem.rangeAR = 30;
        
    }
    
    [_annoItem setTag:_annoItem.missionItem.itemID];
    
    //mandatory
	if ([_annoItem.missionItem.itemType isEqualToString:I_QUIZ] || 
        [_annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_S] || [_annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_E] ||
        [_annoItem.missionItem.itemType isEqualToString:I_START] || [_annoItem.missionItem.itemType isEqualToString:I_END])
		_annoItem.missionItem.mandatory = MANDATORY_Y;
	else
		_annoItem.missionItem.mandatory = MANDATORY_N;
	
    if ([_annoItem.missionItem.itemType isEqualToString:I_START]) _annoItem.missionItem.showType = (NSMutableString *) SHOW_ALL;
    
	_annoItem.missionItem.latitude = recvCoord.latitude;
	_annoItem.missionItem.longitude = recvCoord.longitude;
	
    if([_annoItem.missionItem.itemType isEqualToString:I_MINE] || [_annoItem.missionItem.itemType isEqualToString:I_BLACK])
    {
        [self overlayRefresh];
    }
    
	[self.theMapView addAnnotation:_annoItem];
	self.lastAnno = _annoItem;
    

}


#pragma mark -
#pragma mark action
-(void)editCancelClick 
{
	[itemPicker removeFromSuperview];
	[itemPickerToolbar removeFromSuperview];
	
	//NSArray *allControllers = self.navigationController.viewControllers;
	//MissionBuilder *missionBuilder = [allControllers objectAtIndex:[allControllers count]-2];
	
	//missionBuilder.selectedAnno = self.loadItem;
	
	//Mission *mission = [[[Mission alloc] init] autorelease];
	
	//[mission getDBBuildMissions];
	
	//최초 미션 생성시는 만든미션 삭제
	if (self.mission.mStatus == FIRST_DESIGN)
	{
		//DB 삭제
		MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
		MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
		ItemQuizDao *itemQuizDao = [[[ItemQuizDao alloc] init] autorelease];
        
        
		[missionDao delete:mission];
		
		for ( int i = 0 ; i < [mission.mItems count]; i++ )
		{
			MissionItem *missionItem = [mission.mItems objectAtIndex:i];
			
			for (int j = 0; j < [missionItem.itemQuizzes count]; j++) 
				[itemQuizDao delete:[missionItem.itemQuizzes objectAtIndex:j]];
			
			[missionItemDao delete:missionItem];
		}
	}
	//테스트 용
   // [mission getDBALLBuildMissions];
    //운영용
	[mission getDBBuildMissions];
	
	[self.navigationController popViewControllerAnimated:YES];
	
}	
-(BOOL)localdbInput:(int) status;
{
    BOOL ret = YES;
    ret = [self dataCheck];
    
    if (ret == NO) return ret;
	
    //DB 저장
    MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
	// 미션 아이템 저장
    for (MissionItem *item in self.mission.mItems)
	{
		[missionItemDao save: item];	
    } 
    
	//우선 mission 저장 
	self.mission.mStatus = status;
    self.mission.mWriteDate = [NSDate date];
	MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
	[missionDao save:self.mission];
    
    return ret;
}

-(void)editSaveClick 
{
	
	[itemPicker removeFromSuperview];
	[itemPickerToolbar removeFromSuperview];
	
	if ([self localdbInput:DESIGNING] == NO) return;
    
    [[APPDEL locationManager] stopUpdatingLocation];  
    [[APPDEL locationManager] stopUpdatingHeading];  
    [APPDEL locationManager].delegate = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
    
	/*
     //미입력된 TextField 저장
     if (activeView != nil) {
     if (activeView.tag == MISSION_TITLE) 
     mission.mTitle = (NSMutableString *)activeView.text;
     else if (activeView.tag == MISSION_DESCRIPTION) 
     mission.mDescription = (NSMutableString *)activeView.text;	
     }
     if (activeField != nil) {
     if (activeField.tag == MISSION_PLACE) 
     mission.mDescription = (NSMutableString *)activeField.text;
     }
     */
	
	
}


- (void)gotoLocation
{	
	CLLocationCoordinate2D  cood = recvCoord;
	
    MKCoordinateRegion newRegion;
    
	newRegion.center.latitude = cood.latitude;
	newRegion.center.longitude = cood.longitude;
	
	newRegion.span = theMapView.region.span;

	
	[self.theMapView setRegion:newRegion animated:YES];
}

- (void)gotoCurrentLocation
{	
	CLLocationCoordinate2D  cood = [APPDEL startPoint].coordinate;
	
    MKCoordinateRegion newRegion;
    
	newRegion.center.latitude = cood.latitude;
	newRegion.center.longitude = cood.longitude;
    newRegion.span = theMapView.region.span;
    
	//newRegion.span.latitudeDelta = 0.0001;
	//newRegion.span.longitudeDelta = 0.0001;
	
	[self.theMapView setRegion:newRegion animated:YES];
}

- (void)loadBulidingMission
{
	int i;
	CLLocationCoordinate2D  cood;
	
	for (i = 0; i < [mission.mItems count]; i++)
	{
		AnnoItem *_annoItem = [[[AnnoItem alloc] init] autorelease];
		MissionItem *missionItem = [mission.mItems objectAtIndex:i]; 
		_annoItem.missionItem = missionItem;
		if (i == 0) {
			cood.latitude = missionItem.latitude;
			cood.longitude = missionItem.longitude;
		}
		
		[self.theMapView addAnnotation:_annoItem];
	}
	
	
	MKCoordinateRegion newRegion;
	newRegion.center.latitude = cood.latitude;
	newRegion.center.longitude = cood.longitude;
	newRegion.span = theMapView.region.span;
	//newRegion.span.latitudeDelta = 0.0001;
	//newRegion.span.longitudeDelta = 0.0001;
	
	[self.theMapView setRegion:newRegion animated:YES];
	
}


+ (CGFloat)annotationPadding;
{
	return 10.0f;
}

+ (CGFloat)calloutHeight;
{
	return 40.0f;
}


- (void)showMissionInfo:(id)sender
{
    [self.itemPicker removeFromSuperview];
	[self.itemPickerToolbar removeFromSuperview];	
    
	[self.navigationController setToolbarHidden:YES animated:NO];
	
	MissionBuilderInfo *missionBuilderInfo  = [[[MissionBuilderInfo alloc] initWithNibName: @"MissionBuilderInfo" bundle:  [NSBundle mainBundle]] autorelease];
	missionBuilderInfo.mission = self.mission;
	
	[self.navigationController pushViewController:missionBuilderInfo animated:YES];	
}

- (void)showDetails:(id)sender
{
    /*
    UIButton *btn = (UIButton *)sender;
    AnnoItem * _annoItem =  btn.param1;
    */
	// 피커 내리기
	//if (self.itemPicker.isAccessibilityElement) 	
	[self.itemPicker removeFromSuperview];
	[self.itemPickerToolbar removeFromSuperview];	
    
    
	
	[self.navigationController setToolbarHidden:YES animated:NO];
	
	MissionBuilderDetail *missionBuilderDetail  = [[[MissionBuilderDetail alloc] initWithNibName: @"MissionBuilderDetail" bundle: [NSBundle mainBundle]] autorelease];
    //missionBuilderDetail.annoItem = _annoItem;
	missionBuilderDetail.annoItem = self.selectedAnno;
	
	//if ([self.selectedAnno retainCount]) self.selectedAnno = nil;
    
	[self.navigationController pushViewController:missionBuilderDetail animated:YES];	
}


-(void)openItemPicker:(UITapGestureRecognizer *)gestureRecognizer
{
	
	CGPoint currentPos = [gestureRecognizer locationInView:theMapView];
	
	recvCoord  = [theMapView convertPoint:currentPos toCoordinateFromView:theMapView];
	//NSLog(@"click Pos:%f,%f",recvCoord.latitude,recvCoord.longitude);
	
	[[APPDEL window] addSubview:itemPickerToolbar];
	[itemPickerToolbar setFrame:CGRectMake(0,276,320,44)];
	
	[[APPDEL window] addSubview:itemPicker];
	[itemPicker setFrame:CGRectMake(0,320,320,160)];
	
	
	[self gotoLocation];
	
    
	//여기서 피커 선택 해서 세팅하면 처음에 나온다 
    
    [self selectionChanged:pickerSelection];
    
	
    
}




-(void)pickerDoneClick
{
	[self.itemPicker removeFromSuperview];
	[self.itemPickerToolbar removeFromSuperview];	
    
}

-(void)pickerCancelClick
{

    
	if (self.lastAnno != nil) 
	{
        
		[self.theMapView removeAnnotation:self.lastAnno];
		[self.mission.mItems removeObject:self.lastAnno.missionItem];
        
        if([lastAnno.missionItem.itemType isEqualToString:I_MINE] || [lastAnno.missionItem.itemType isEqualToString:I_BLACK])
        {
            [self overlayRefresh];
        }
        else if ([lastAnno.missionItem.itemType isEqualToString:I_TIMEOUT_S]) {
            [self.theMapView removeAnnotation:lastAnno2];
            [self.mission.mItems removeObject:lastAnno2.missionItem];
        }
		self.lastAnno = nil;
        self.lastAnno2 = nil;
	}
	[itemPicker removeFromSuperview];
	[itemPickerToolbar removeFromSuperview];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	NSLog(@"gestureRecognizer shouldReceiveTouch");
	if ([touch.view isKindOfClass:[MKAnnotationView class]]) {
		return NO;
	}
	/*
	 else if ([touch.view isKindOfClass:[MKAnnotationView class]]) {
	 return NO;
	 }
	 */
	else{	
		return YES;
	}
	
}

#pragma mark -
#pragma mark mapView protocol

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{
    /*
     MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
     circleView.fillColor = [UIColor redColor];
     circleView.alpha = 0.3;
     return [circleView autorelease];
     */
    
    CircleItem *_tmpItem = (CircleItem *)overlay;
    MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
    
    
    if([_tmpItem.missionItem.itemType isEqualToString:I_MINE])
    {
        circleView.fillColor = [UIColor redColor];
        circleView.alpha = 0.3;
    }
    else if([_tmpItem.missionItem.itemType isEqualToString:I_BLACK]) {
        
        circleView.fillColor = [UIColor blackColor];
        circleView.alpha = 0.3;
    }
    return [circleView autorelease];
    
    
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if ([view.annotation isKindOfClass:[MKUserLocation class]])
		return;
	
	self.selectedAnno = (AnnoItem *)view.annotation;
	self.selectedAnno.tag = [self.theMapView.annotations indexOfObject:view.annotation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	// no pin if this is the user location.  we want the dot and concnetric circle, and continual updates.
	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
    /*
    static NSString *AnnotationViewID = @"annotationViewID";
    MKAnnotationView *annotationView = (MKAnnotationView *)[theMapView  dequeueReusableAnnotationViewWithIdentifier:AnnotationViewID];
    
	if ([[annotation title] isEqualToString:NSLocalizedString(@"Current Location",@"")])  {
        MKPinAnnotationView *pin = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID] autorelease];
        annotationView = pin;
    }
     */
       
	if ([annotation isKindOfClass:[AnnoItem class]]) // for Golden Gate Bridge
	{
		AnnoItem *_tmpItem = (AnnoItem *)annotation;
		
		if (_tmpItem != nil) 
		{
			NSString  *identifier = [NSString stringWithFormat:@"%d%d%@", _tmpItem.missionItem.itemID,_tmpItem.missionItem.mandatory,_tmpItem.missionItem.itemType];
			MKAnnotationView *pinView = (MKAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];		
			
			NSLog(@"_tmpItem.missionItem.itemType:%@", _tmpItem.missionItem.itemType);			
			
			if (!pinView)
			{
				// if an existing pin view was not available, create one
				MKAnnotationView* customPinView = [[[MKAnnotationView alloc]
                                                    initWithAnnotation:annotation reuseIdentifier:identifier] autorelease];
				//[customPinView becomeFirstResponder];
				customPinView.tag = _tmpItem.missionItem.itemID + 300;
                
                
				//customPinView.pinColor = MKPinAnnotationColorPurple;
				//customPinView.animatesDrop = YES;
				customPinView.canShowCallout = YES;
				customPinView.draggable = YES;
				
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
				
				UIImage *flagImage = [UIImage imageNamed:imgFile];
				resizeRect.size = flagImage.size;
				
				
				CGSize maxSize = CGRectInset(self.view.bounds,
											 [MissionBuilder annotationPadding],
											 [MissionBuilder annotationPadding]).size;
				maxSize.height -= self.navigationController.navigationBar.frame.size.height + [MissionBuilder calloutHeight];
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
				if (![_tmpItem.missionItem.itemType isEqualToString:I_MINE])
				{
					customPinView.opaque = NO;
					customPinView.centerOffset = CGPointMake(0,-resizeRect.size.height / 2);
				}
				
                
                
				UIImageView *sfIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SFIcon.png"]];
				customPinView.leftCalloutAccessoryView = sfIconView;
				[sfIconView release];
				
                /*
                ParamButton *rightButton = [ParamButton buttonWithType:UIButtonTypeDetailDisclosure];
                
                rightButton.param1 = (AnnoItem *)customPinView.annotation;
                */
                
                
				UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                rightButton.tag = customPinView.tag;
                
                [rightButton addTarget:self 
								action:@selector(showDetails:)
					  forControlEvents:UIControlEventTouchUpInside];
				
				//매개변수를 가지고 바로 실행한다
				//[self performSelector:@selector(showDetails:) withObject:_tmpItem];
				customPinView.rightCalloutAccessoryView = rightButton;
				[customPinView setAnnotation:annotation];
				
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
-(void)overlayRefresh
{
    if ([[theMapView overlays] count] >0 ) {
        [theMapView removeOverlays:[theMapView overlays]];
    }
    for (int i = 0; i < [self.mission.mItems count]; i++)
    {
        MissionItem *missionItem = [self.mission.mItems objectAtIndex:i];
        
        if ([missionItem.itemType isEqualToString:I_MINE] || [missionItem.itemType isEqualToString:I_BLACK])
        {
            CLLocationCoordinate2D  cood;
            cood.latitude = missionItem.latitude;
            cood.longitude = missionItem.longitude;
            
            CircleItem *circle = (CircleItem *)[CircleItem circleWithCenterCoordinate:cood radius:missionItem.rangeAR];
            circle.missionItem  = missionItem;
            
            [theMapView addOverlay:circle];
        }
    }
    
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState 
   fromOldState:(MKAnnotationViewDragState)oldState
{
    if ([annotationView.annotation isKindOfClass:[AnnoItem class]]) // for Golden Gate Bridge
	{
		AnnoItem *_tmpItem = (AnnoItem *)annotationView.annotation;
        
        CLLocationCoordinate2D  cood;
        cood.latitude = _tmpItem.missionItem.latitude;
        cood.longitude = _tmpItem.missionItem.longitude;
        
        for (CircleItem *circle in [theMapView overlays] ) {
            if([circle.missionItem isEqual:_tmpItem.missionItem])
            {
                [theMapView removeOverlay:circle];
                
                CircleItem *circle = (CircleItem *)[CircleItem circleWithCenterCoordinate:cood radius:_tmpItem.missionItem.rangeAR];
                circle.missionItem  = _tmpItem.missionItem;
                
                [theMapView addOverlay:circle];
            }
        }
    }
}

@end
