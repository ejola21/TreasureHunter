//
//  MissionListDetailController.m
//  TreasureHunter
//
//  Created by  on 12. 6. 15..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "MissionListDetailController.h"
#import "TreasureHunterAppDelegate.h"
#import "MissionPlay.h"
#import "MissionInPlayDao.h"
#import "Mission.h"
#import "HTTPRequest.h"
#import "JSON.h"
#import "MissionDao.h"
#import "MissionItemDao.h"
#import "ItemQuizDao.h"
#import "MissionItemInPlayDao.h"
#import "MissionInPlay.h"
#import "SVProgressHUD.h"
#import "DLStarRatingControl.h"
#import "StartGameAlert.h"
//#import <GameKit/GameKit.h>

@interface MissionListDetailController ()

@end

@implementation MissionListDetailController
@synthesize navigationTitle;
@synthesize tableView;
@synthesize mission;
@synthesize naviBar;
@synthesize missionDic;
@synthesize isTest;
@synthesize listCaller;
//@synthesize localPlayer;

#pragma mark -
#pragma mark Life Cycle Functions

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    isPlayed = false;
    
    mission = [[Mission alloc] init];
    replyList = [[NSMutableArray alloc] init];
    
    missionID = [missionDic objectForKey:@"MissionID"];
    play = [[missionDic objectForKey:@"PlayCnt"] intValue];
    fail = [[missionDic objectForKey:@"FailCnt"] intValue];
    recommend = [[missionDic objectForKey:@"RecommendCnt"] intValue];
    recommendAvg = [[missionDic objectForKey:@"RecommendAvg"] intValue];
    
    CGRect tableViewFrame = CGRectMake(0.0, 44.0, self.view.bounds.size.width, self.view.bounds.size.height-44.0);
    tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    tableView.delegate = self;
    tableView.dataSource = self;
    
    [self.view addSubview:tableView];
    
    [self.navigationTitle setTitle:NSLocalizedString(@"detail_11", nil)];
    [self.naviBar setTintColor:[APPDEL backColor]];
    
    MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
    
	NSMutableArray *missions = [[[NSMutableArray alloc] init] autorelease];
	missions = [missionDao selectAll];
    
    int cnt =  [missions count];
    totalCnt = 0;
    mandatoryCnt = 0;
    BOOL missionSaved = false;
    for (int i = 0 ; i < cnt ; i++) 
    {
        Mission *_mission = [missions objectAtIndex:i];  
        if ([_mission.mID isEqualToString:missionID])
        {
            self.mission = _mission;
            missionSaved = true;
            break;
        }
    }
    if(!missionSaved){
        [self httpSend:missionID]; 
    }else{
        
        MissionItemDao *itemDao = [[[MissionItemDao alloc] init] autorelease];
        NSMutableArray *items = [itemDao selectAt:self.mission.mID];
        for (MissionItem *item in items)
        {
            totalCnt ++;
            if( item.mandatory == MANDATORY_Y)
            {     
                mandatoryCnt++;
            }
           
        }
    }
    if(!isTest){
        [self getMissionReply]; 
    }
    
    
}



- (void)viewDidUnload
{
    [tableView release];
    tableView = nil;
    [self setNavigationTitle:nil];
    [self setNaviBar:nil];
    [super viewDidUnload];
    
}
- (void)viewWillAppear:(BOOL)animated {
    [APPDEL locationManagerInit:self];
    [APPDEL setStartPoint: [[APPDEL locationManager] location]];
    NSLog(@"MissionListDetail latitude %+.6f, longitude %+.6f\n",[APPDEL startPoint].coordinate.latitude,[APPDEL startPoint].coordinate.longitude);
	[super viewWillAppear:animated];
    [APPDEL tabBarController].tabBar.hidden = FALSE;
}

- (void)viewWillDisappear:(BOOL)animated{
    [SVProgressHUD dismiss];
}
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {  
    if(newLocation.horizontalAccuracy < 0.0) return;
    
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        NSLog(@"AppDel latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        [APPDEL setStartPoint: newLocation];
    }
	
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

    NSMutableString *errorString = [[[NSMutableString alloc] init] autorelease];
	
	if ([error domain] == kCLErrorDomain) {
		
		// We handle CoreLocation-related errors here
		
		switch ([error code]) {
				// This error code is usually returned whenever user taps "Don't Allow" in response to
				// being told your app wants to access the current location. Once this happens, you cannot
				// attempt to get the location again until the app has quit and relaunched.
				//
				// "Don't Allow" on two successive app launches is the same as saying "never allow". The user
				// can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
				//
			case kCLErrorDenied:
				[errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationDenied", nil)];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"locationDenied_title", nil)
                                                                    message: NSLocalizedString(@"locationDenied_msg", nil)
                                                                   delegate:nil 
                                                          cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                                          otherButtonTitles:nil];
                [alertView show];
                [alertView release];
             
				break;
				
				// This error code is usually returned whenever the device has no data or WiFi connectivity,
				// or when the location cannot be determined for some other reason.
				//
				// CoreLocation will keep trying, so you can keep waiting, or prompt the user.
				//
			case kCLErrorLocationUnknown:
				[errorString appendFormat:@"%@\n", NSLocalizedString(@"LocationUnknown", nil)];
				break;
				
				// We shouldn't ever get an unknown error code, but just in case...
				//
			default:
				[errorString appendFormat:@"%@ %d\n", NSLocalizedString(@"GenericLocationError", nil), [error code]];
				break;
		}
	} else {
		// We handle all non-CoreLocation errors here
		// (we depend on localizedDescription for localization)
		[errorString appendFormat:@"Error domain: \"%@\"  Error code: %d\n", [error domain], [error code]];
		[errorString appendFormat:@"Description: \"%@\"\n", [error localizedDescription]];
	}

}


-(void)getPlayTime{
    MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc] init] autorelease];
	MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:missionID playerID:[APPDEL gUserID]];
    NSLog(@"mission in play %@",missionInPlay);
    if(missionInPlay !=nil && missionInPlay.startTime != nil && missionInPlay.endTime != nil){
        NSTimeInterval timeInterval = [missionInPlay.endTime timeIntervalSinceDate:missionInPlay.startTime];
        NSLog(@"time interval %f",timeInterval);
        if(timeInterval > 0){
            mPlayTimeString = [[self stringFromTimeInterval:timeInterval] retain];
        }else{
            mPlayTimeString = @"";
        }
    }else{
        mPlayTimeString = @"";
    }
    NSLog(@"mplay String%@", mPlayTimeString);
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    
    [APPDEL locationManager].delegate = nil;
    [[APPDEL locationManager] stopUpdatingLocation];
    [mission release];
    [replyList release];
    
    [tableView release];
    [navigationTitle release];
    [naviBar release];
    [super dealloc];
}

#pragma mark -
#pragma mark Load Mission Functions






- (void)getMissionReply{
    [SVProgressHUD showWithStatus:@"Loading.."];
    
    // 1. Get the string from the given url.
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"300",       @"tr",
                                missionID,					@"missionID",
                                nil];
    
	NSLog(@"bodyObject:%@",bodyObject);
    
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didReplyReceiveFinished:)];
	// 페이지 호출
    
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php" ] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
    
}



- (void)didReplyReceiveFinished:(NSString *)result{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        
        [replyList removeAllObjects];
        if(svrArr !=nil){
            [replyList addObjectsFromArray:svrArr];  
        }
    }
    [self getPlayTime];
    [tableView reloadData];
    [SVProgressHUD dismiss];
}

- (void)httpSend:(NSString *) str
{
    [SVProgressHUD showWithStatus:@"Loading.."];
    
    
    // 1. Get the string from the given url.
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"200",       @"tr",
                                str,		  @"missionID",
                                nil];
    
	NSLog(@"bodyObject:%@",bodyObject);
    
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];
	// 페이지 호출
    
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php" ] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
}

- (void)didReceiveFinished:(NSString *)result
{
    NSLog(@"http result :%@",result);
    
    if (![result isEqualToString:@"FAIL"])
    {
		NSArray *_head = [result componentsSeparatedByString:@"^"];
		SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
		
		//NSRange range = {1,2};
		NSString *_data;
		NSArray *svrArr;
		for (int k = 1; k <_head.count; k++ ) 
		{
			_data = [_head objectAtIndex:k];
			
			svrArr = (NSArray *)[jsonParser objectWithString:[_data substringFromIndex:1] error:NULL];
            
			
			if ([_data hasPrefix:@"M"]) 
			{
				for (int i = 0; i < svrArr.count; i++)
				{
					NSDictionary *dic = [svrArr objectAtIndex:i];
					
					self.mission.mID = [dic objectForKey:@"MissionID"];
                    
					self.mission.mTitle = [dic objectForKey:@"Title"];
					self.mission.mDescription = [dic objectForKey:@"Description"];
					self.mission.mPlace = [dic objectForKey:@"Place"];
					self.mission.mDesigner = [dic objectForKey:@"Designer"];
                 //   self.mission.mStartTime = [APPDEL toGMTNSDate:[dic objectForKey:@"StartTime"]:@"yyyy-MM-dd HH:mm:ss"];
					self.mission.mRunLimitTime = [APPDEL toGMTNSDate:[dic objectForKey:@"RunLimitTime"]:@"yyyy-MM-dd HH:mm:ss"];
					self.mission.mStatus = [[dic objectForKey:@"Status"] intValue];
					self.mission.mQuiz = [dic objectForKey:@"Quiz"];
					self.mission.mAnswer = [dic objectForKey:@"Answer"];
					self.mission.mVirtual = [[dic objectForKey:@"Virtual"] intValue];
                    self.mission.mWriteDate = [APPDEL toGMTNSDate:[dic objectForKey:@"WriteDate"]:@"yyyy-MM-dd HH:mm:ss"];
					MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
					[missionDao save:mission];
				}
			}
			else if ([_data hasPrefix:@"I"]) 
			{
                totalCnt = svrArr.count;
				for (int i = 0; i < svrArr.count; i++)
				{
					NSDictionary *dic = [svrArr objectAtIndex:i];
					
					MissionItem *mItem = [[[MissionItem alloc] init] autorelease];
					mItem.missionID = [dic objectForKey:@"MissionID"];
					mItem.itemID		= [[dic objectForKey:@"ItemID"] intValue];
					mItem.mandatory = [[dic objectForKey:@"Mandatory"] intValue];
					mItem.itemType	= [dic objectForKey:@"ItemType"];
					mItem.latitude	= [[dic objectForKey:@"Latitude"] doubleValue];
					mItem.longitude = [[dic objectForKey:@"Longitude"] doubleValue];
					mItem.blackCnt	= [[dic objectForKey:@"BlackCnt"] intValue];
					mItem.blackTime = [[dic objectForKey:@"BlackTime"] intValue];
					mItem.rangeAR		=	[[dic objectForKey:@"RangeAR"] intValue];
					mItem.showType  = [dic objectForKey:@"ShowType"];
					mItem.effectiveTime = [[dic objectForKey:@"EffectiveTime"] intValue];
					mItem.effectiveRange		=	[[dic objectForKey:@"EffectiveRange"] intValue];
					mItem.itemGame  = [[dic objectForKey:@"ItemGame"] intValue];
					mItem.info			= [dic objectForKey:@"Info"];
					mItem.relationItemID = [[dic objectForKey:@"RelationItemID"] intValue];
					
					[self.mission.mItems addObject:mItem];
					MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
					[missionItemDao save:mItem];
                    
                    if(mItem.mandatory == MANDATORY_Y)
                    {     
                        mandatoryCnt++;
                    }
				}
			}
			else if ([_data hasPrefix:@"Q"]) 
			{
				for (int i = 0; i < svrArr.count; i++)
				{
					NSDictionary *dic = [svrArr objectAtIndex:i];
					
					ItemQuiz *quiz	= [[[ItemQuiz alloc] init] autorelease];
					quiz.missionID	= [dic objectForKey:@"MissionID"];
					quiz.itemID			= [[dic objectForKey:@"ItemID"] intValue];
					quiz.seq				= [[dic objectForKey:@"Seq"] intValue];
					quiz.quiz				= [dic objectForKey:@"Quiz"];
					quiz.answer			= [dic objectForKey:@"Answer"];
					quiz.probability	= [[dic objectForKey:@"Probability"] intValue];
					
					for (int j = 0; j < self.mission.mItems.count; j++) 
					{
						MissionItem *_mItem = [self.mission.mItems objectAtIndex:j];
						if (quiz.itemID == _mItem.itemID) 
						{
							[_mItem.itemQuizzes addObject:quiz]; 
							break;
						}
					}
					ItemQuizDao *itemQuizDao = [[[ItemQuizDao alloc] init] autorelease];
					[itemQuizDao save:quiz];
				}
			}
			
		}
        [APPDEL setPlayMission:mission];
	}
	[tableView reloadData];
    [SVProgressHUD dismiss];
    
}


#pragma mark -
#pragma mark TableView Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3; 
}


- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    int tempInt = 0;
    
    switch (section) {
		case 0:
            if(![self stringIsEmpty:[missionDic objectForKey:@"ShortUser1"]]){
                tempInt += 2;
            }
            if(![self stringIsEmpty:mPlayTimeString]){
                tempInt +=2;
            }
			return 8+tempInt;
            break;
		case 1:
            return 2;
			break;
        case 2:
			return [replyList count]*2;
			break;
	}
    return 0;
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    CGFloat labelHeight = 32;
    
    if(indexPath.section == 2 && indexPath.row%2 == 1){
        if(row <= [replyList count]*2){
            UILabel *myLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 260)] autorelease];
            myLabel.numberOfLines = 0;
            myLabel.lineBreakMode = UILineBreakModeWordWrap;
            
            NSDictionary *dic = [replyList objectAtIndex:(int)(row/2)];
            myLabel.text = [dic objectForKey:@"MReply"];
            CGSize labelSize = [myLabel.text sizeWithFont:myLabel.font 
                                        constrainedToSize:myLabel.frame.size 
                                            lineBreakMode:UILineBreakModeWordWrap];
            labelHeight = labelSize.height+10;
            
            if(labelHeight <32){
                labelHeight = 32;
            }
        }else{
            labelHeight = 32;
        }
    }else if(indexPath.section == 0){
        UILabel *myLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 260)] autorelease];
        myLabel.numberOfLines = 0;
        myLabel.lineBreakMode = UILineBreakModeWordWrap;
        myLabel.text = @"";
        if(indexPath.row == 1){
            myLabel.text = mission.mTitle;
        }else if(indexPath.row == 3){
            myLabel.text = mission.mDescription;
        }else if(indexPath.row == 5){
            myLabel.text = mission.mPlace;
        }
        CGSize labelSize = [myLabel.text sizeWithFont:myLabel.font 
                                    constrainedToSize:myLabel.frame.size 
                                        lineBreakMode:UILineBreakModeWordWrap];
        labelHeight = labelSize.height+10;
        
        if(labelHeight <32){
            labelHeight = 32;
        }
    }
    
    return labelHeight;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = indexPath.row;
    
	
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
		cell = [[[UITableViewCell alloc] init] autorelease];
    }
    
    if(indexPath.section == 0) {
		if(row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            label.text =  NSLocalizedString(@"detail_info_0", nil);
            label = (UILabel *)[cell viewWithTag:1];
            label.text = [NSString stringWithFormat:@"Designer : %@", [self trimUserID:mission.mDesigner]];
		}else if(row == 1){
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
            cell.textLabel.text = mission.mTitle;
		}else if(row == 2){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            label.text =  NSLocalizedString(@"detail_info_1", nil);
            
        }else if(row == 3){
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
            cell.textLabel.text = mission.mDescription;
        }else if(row == 4){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            label.text =  NSLocalizedString(@"detail_info_2", nil);
        }else if(row == 5){
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
            cell.textLabel.text = mission.mPlace;
        }else if(row == 6){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            label.text = NSLocalizedString(@"detail_info_7", nil);
            
        }else if(row == 7){
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"detail_info_8", nil), totalCnt, mandatoryCnt];
        }else if(row == 8){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            if([self stringIsEmpty:[missionDic objectForKey:@"ShortUser1"]]){
                label.text = NSLocalizedString(@"detail_info_6", nil);
            }else{
                label.text = NSLocalizedString(@"detail_info_3", nil);
            }
        }else if(row == 9){
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
            if([self stringIsEmpty:[missionDic objectForKey:@"ShortUser1"]]){
                cell.textLabel.text = mPlayTimeString;
            }else{
                cell.textLabel.text = [NSString stringWithFormat:@"%@ : %@",[self trimUserID:[missionDic objectForKey:@"ShortUser1"]],[missionDic objectForKey:@"ShortRecord1"]];
            }
        }else if(row == 10){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            label.text = NSLocalizedString(@"detail_info_6", nil);
        }else {
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
            cell.textLabel.text = mPlayTimeString;
        }
    }else if(indexPath.section == 1) {
		if(row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            
            NSDateFormatter *today = [[[NSDateFormatter alloc]init] autorelease];
            [today setDateFormat:@"yyyy-MM-dd"];
            if([today stringFromDate:mission.mWriteDate] ==nil){
                label.text = NSLocalizedString(@"detail_info_4", nil);
            }else{
                label.text = [NSString stringWithFormat:NSLocalizedString(@"detail_info_5", nil),[APPDEL toGMTNSString:mission.mWriteDate :@"yyyy-MM-dd"]];
                //label.text = [NSString stringWithFormat:NSLocalizedString(@"detail_info_5", nil),[today stringFromDate:mission.mWriteDate]];
            }
		}else {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MissionDetailCellA" owner:self options:nil] objectAtIndex:0];
            
            
            DLStarRatingControl *customNumberOfStars = [[[DLStarRatingControl alloc] initWithFrame:CGRectMake(0, 0, 110, 25) andStars:5 isFractional:true setSize0to20:15 clickEnabled:false] autorelease];
            customNumberOfStars.rating = recommendAvg;
            
            UIView *starView = (UIView *)[cell viewWithTag:100];
            [starView addSubview:customNumberOfStars];
            
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:1];
            label.text = [NSString stringWithFormat:@"Play(%d) Fail(%d)",play, fail];
		}
    }else if(indexPath.section == 2) {
		if(row%2 == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MissionDetailCellB" owner:self options:nil] objectAtIndex:0];
            
            [cell setBackgroundColor:[APPDEL backColor]];
            DLStarRatingControl *customNumberOfStars = [[[DLStarRatingControl alloc] initWithFrame:CGRectMake(0, 0, 110, 25) andStars:5 isFractional:true setSize0to20:15 clickEnabled:false] autorelease];
            customNumberOfStars.rating = 5.0;
            
            UIView *starView = (UIView *)[cell viewWithTag:100];
            [starView addSubview:customNumberOfStars];
            
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:1];
            label.text = @"test@gmail.com";
            
            if(row <= [replyList count]*2){
                NSDictionary *dic = [replyList objectAtIndex:(int)(row/2)];
                
                customNumberOfStars.rating = [[dic objectForKey:@"RecommendScore"] floatValue];
                
                label.text = [self trimUserID:[dic objectForKey:@"UserID"]];                
            }
		}else {
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
            if(row <= [replyList count]*2){
                NSDictionary *dic = [replyList objectAtIndex:(int)(row/2)];
                cell.textLabel.numberOfLines = 0;
                cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
                cell.textLabel.text = [dic objectForKey:@"MReply"];
                
            }
            
		}
    }
    
    return cell;
}


- (NSString *)trimUserID:(NSString*)userId{
    NSRange subRange;
    subRange = [userId rangeOfString : @"@"];
    if(subRange.location == NSNotFound){
        return userId;
    }
    return [userId substringToIndex : subRange.location];   
}




#pragma mark -
#pragma mark UI Functions



- (IBAction)setClickList:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    
    if(listCaller != nil && isPlayed){
        [listCaller getList:0];
        [listCaller.segmenteControl setSelectedSegmentIndex:0];
        [listCaller.tableView  setContentOffset:CGPointMake(0, 0) animated:false];
    }
}

- (IBAction)setClickPlay:(id)sender {
    
    
	if((mission.mStartTime != nil) && (mission.mStartTime != 0) && ([[NSDate date] earlierDate:mission.mStartTime] != mission.mStartTime)) {
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"detail_2", nil) 
                                                            message:[NSString stringWithFormat:@"%@:%@",
                                                                     NSLocalizedString(@"detail_3", nil),
                                                                     [dateFormatter stringFromDate:mission.mStartTime]]
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                                  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		[dateFormatter release];
		return;
	}
    
    int startKind = 0;
    
    MissionInPlayDao *missionInPlayDao = [[[MissionInPlayDao alloc]init] autorelease];
    MissionInPlay *missionInPlay = [missionInPlayDao selectWithPK:mission.mID
                                                         playerID:[APPDEL gUserID]];
    if(missionInPlay !=nil){
        if([missionInPlay.startYN isEqualToString:@"Y"] && [missionInPlay.endYN isEqualToString:@"N"]){
            startKind = 1;
        }
    }
    StartGameAlert  *alertview = [[StartGameAlert alloc] initWithKind:startKind];
    [alertview setDelegate:self];
    [alertview show];
    [alertview release];
	
}


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    MissionPlay *missionPlay = [[[MissionPlay alloc] initWithNibName:@"MissionPlay" bundle: [NSBundle mainBundle]] autorelease];
    missionPlay.missionDetail = self;
    missionPlay.hidesBottomBarWhenPushed = YES;
    [[APPDEL playingDic] setObject:mission.mID forKey:@"missionID"];
    [[APPDEL playingDic] setObject:self.missionDic forKey:@"missionDic"];
    [[APPDEL playingDic] setObject: [NSNumber numberWithBool:[(StartGameAlert *)alertView isVirtural]] forKey:@"isVirtualMode"]; 
    
    if(buttonIndex == 0){
        isPlayed = true;
        [self missionCheck];
        [[APPDEL playingDic] setObject: [NSNumber numberWithInt:0] forKey:@"isNewStart"];
        [self.navigationController pushViewController:missionPlay animated:YES]; 
    }else if(buttonIndex == 1){
        isPlayed = true;
        [[APPDEL playingDic] setObject: [NSNumber numberWithInt:1] forKey:@"isNewStart"];
		[self.navigationController pushViewController:missionPlay animated:YES];
    }
}

-(void) missionCheck;
{
	MissionItemDao *itemDao = [[[MissionItemDao alloc] init] autorelease];
	MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
	
	NSMutableArray *items = [itemDao selectAt:self.mission.mID];
	for (MissionItem *item in items) {
		MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                selectWithPK:item.missionID
                                                playerID:[APPDEL gUserID] itemID:item.itemID];
		if (missionItemInPlay == nil) {
			UIAlertView *alertView;
			alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"detail_0", nil)
                                                   message:NSLocalizedString(@"detail_1", nil)
                                                  delegate:nil 
                                         cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                         otherButtonTitles:nil];
			[alertView show];
			[alertView release];
			return;
		}
	}								 
}

@end
