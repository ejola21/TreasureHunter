//
//  MissionBuilderList.m
//  TreasureHunter
//
//  Created by ejola on 11. 3. 16..
//  Copyright 2011 __MyCompanyName__. All rights reserved.

#import "MissionBuilderList.h"
#import "TreasureHunterAppDelegate.h"
#import "Mission.h"
#import "MissionBuilder.h"
#import "MissionDao.h"
#import "MissionItemDao.h"
#import "ItemQuizDao.h"
#import "ImageManager.h"
#import "HTTPRequest.h"
#import "MissionListDetailController.h"
#import "SVProgressHUD.h"
#import "JSON.h"

@implementation MissionBuilderList


#pragma mark -
#pragma mark View lifecycle

@synthesize tableView;


- (void)viewDidLoad {
	[super viewDidLoad];
	
	Mission *mission = [[[Mission alloc] init] autorelease];
    //테스트용
    //[mission getDBALLBuildMissions];
	
    //운영용
    [mission getDBBuildMissions];
    
	uMission = [[Mission alloc] init];
	
    CGRect tableViewFrame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
    tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [tableView setBackgroundColor:[UIColor whiteColor]];
    tableView.delegate = self;
    tableView.dataSource = self;
    
    [self.view addSubview:tableView];
    
    UIBarButtonItem *eBtnPlus = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:self
                                                                             action:@selector(btnPlusClick)];
    
    UIBarButtonItem *eBtnEdit = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                             target:self
                                                                             action:@selector(btnEditClick)];
    
    
    [self.navigationItem setRightBarButtonItem:eBtnPlus animated:YES];
    [self.navigationItem setLeftBarButtonItem:eBtnEdit animated:YES];
	[self.navigationItem setTitle:NSLocalizedString(@"builer_list_title", nil)];
    [self.navigationController.navigationBar setTintColor:[APPDEL backColor]];
    
    
    [eBtnPlus release];
    [eBtnEdit release];
    //	
	
	//self.tableView.s UITableViewCellEditingStyleNone;
	
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}



- (void)viewWillAppear:(BOOL)animated {
    
    self.navigationController.navigationBarHidden = NO;
    
	[super viewWillAppear:animated];
	//[[APPDEL tabBarController].view setFrame:CGRectMake(0, 0, 320, 460)]; 
	//[[APPDEL tabBarController].tabBar setFrame:CGRectMake(0,392, 320, 48)];
    //NSLog(@"tableView:%@",self.tableView);
	[self.tableView reloadData];
}


#pragma mark -
#pragma mark util


#pragma mark -
#pragma mark action



-(void)btnPlusClick  {
    [self.navigationController setToolbarHidden:YES animated:NO];
	
	MissionBuilder *missionBuilder  = [[MissionBuilder alloc] initWithNibName: @"MissionBuilder" bundle:[NSBundle mainBundle]];
	missionBuilder.hidesBottomBarWhenPushed = YES;
	Mission *mission = [[Mission alloc] init];
	mission.mStatus = FIRST_DESIGN;
	[[APPDEL buildingMissions] addObject:mission];
	
	missionBuilder.mission = mission;
	[mission release];
	[self.navigationController pushViewController:missionBuilder animated:YES];
    [missionBuilder release];
    
}

-(void)btnEditClick  {
    [self.tableView setEditing:![self tableView].editing];
}

#pragma mark -
#pragma mark Upload Functions

-(void)uploadServer :(Mission *)mission
{
	
    [SVProgressHUD showWithStatus:@"Loading.."];
    // 접속할 주소 설정
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
    
    [ImageManager uploadImgWithID:mission.mID Image:[ImageManager loadInfoBadgeImg:mission.mID]];
    
    //테스트 할때는 밑에꺼 지우면 서버에 올라간것도 단말에서 보인다
    
     MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
     mission.mStatus = SERVER_UPLOAD;
     [missionDao save:mission];
     /* 테스트 End */
    
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정
    NSString *sMission = [NSString stringWithFormat:@"%@}}%@}}%@}}%@}}%@}}%@}}%d}}%@}}%@}}%d}}%@}}%@",
                          mission.mID,           
                          mission.mTitle,        
                          mission.mDescription,  
                          mission.mPlace,        
                          mission.mDesigner,     
                          mission.mRunLimitTime, 
                          mission.mStatus,       
                          mission.mQuiz,         
                          mission.mAnswer,       
                          mission.mVirtual, 
                          mission.mLang,
                          mission.mWriteDate];    
    
    //row구분 **
    NSString *sMissionItem = @"";
    NSString *sItemQuiz = @"";
    
    
    for (int i = 0; i < [mission.mItems count]; i++)
	{
		MissionItem *missionItem = [mission.mItems objectAtIndex:i];
        
        //passedTime.text =  [APPDEL toNSString:passedDate :@"HH:mm:ss"];
        
		NSString *ss = [NSString stringWithFormat:@"%@}}%d}}%d}}%@}}%f}}%f}}%d}}%d}}%d}}%@}}%d}}%d}}%d}}%@}}%d}}%@**"
                        ,missionItem.missionID 	
                        ,missionItem.itemID 		
                        ,missionItem.mandatory 	
                        ,missionItem.itemType 	
                        ,missionItem.latitude 	
                        ,missionItem.longitude 	
                        ,missionItem.blackCnt 	
                        ,missionItem.blackTime 	
                        ,missionItem.rangeAR 	
                        ,missionItem.showType 		
                        ,missionItem.effectiveRange 	
                        ,missionItem.effectiveTime 	
                        ,missionItem.itemGame 		
                        ,missionItem.info 			
                        ,missionItem.relationItemID 	
                        ,mission.mWriteDate]; 		
        
        sMissionItem = [sMissionItem stringByAppendingString:ss];
        
        for (int j = 0; j < [missionItem.itemQuizzes count]; j++) 
        {
            ItemQuiz *itemQuiz = [missionItem.itemQuizzes objectAtIndex:j];
            
            NSMutableString *qq = [NSString stringWithFormat:@"%@}}%d}}%d}}%@}}%@}}%d**"
                                   ,itemQuiz.missionID 	
                                   ,itemQuiz.itemID 		
                                   ,itemQuiz.seq 		
                                   ,itemQuiz.quiz 		
                                   ,itemQuiz.answer 		
                                   ,itemQuiz.probability]; 
            
            sItemQuiz = [sItemQuiz stringByAppendingString:qq];
        }
        
	}
    
    //NSLog(@"mission:%@",mission);
    //NSLog(@"sMission:%@",sMission);
    // Dictionay 특성 조심 nil 이면 다음 항목 전송 안딤
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"700",             @"tr",
                                sMission,           @"mission", 
                                sMissionItem,       @"missionItem",
                                sItemQuiz,          @"itemQuiz",
                                
                                nil];
	NSLog(@"bodyObject:%@",bodyObject);
    
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];
	// 페이지 호출
	[httpRequest requestUrl:url bodyObject:bodyObject];
	//[indicator startAnimating];
    
    
}

- (void)didReceiveFinished:(NSString *)result
{
    
    if ([[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@"SUCCESS"])
    {
        [[APPDEL buildingMissions] removeObject:uMission];
        [tableView reloadData];
    }
    else {
        NSLog(@"MissionBuilderList didReceiveFinished:%@",result); 
    }
    
    [self httpGetDesign];
    
}

- (void)httpGetDesign
{
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"600",@"tr",
                                [APPDEL gUserID],@"id", nil];
    [httpRequest setDelegate:self selector:@selector(didReceiveDesignFinished:)];
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
}

- (void)didReceiveDesignFinished:(NSString *)result
{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        if(svrArr !=nil){
            [[APPDEL designedArray] removeAllObjects]; 
            [[APPDEL designedArray] addObjectsFromArray:svrArr]; 
            [APPDEL setDesignCount:[[APPDEL designedArray] count]];
            for(int i = 0 ; i < [APPDEL designCount]; i++){
                [APPDEL checkNAddDesignImg:[[[APPDEL designedArray] objectAtIndex:i]objectForKey:@"MissionID"]];
            }        
        }
    }
    [SVProgressHUD dismiss];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
	return [[APPDEL buildingMissions] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)mTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [mTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MissionBuilderListCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
	[cell setBackgroundColor:[APPDEL cellColor]];
	// Configure the cell...
	Mission *mission = [[APPDEL buildingMissions] objectAtIndex:indexPath.row];
    
	UILabel *label;
	label = (UILabel *)[cell viewWithTag:201];
	label.text = mission.mTitle;
	
	label = (UILabel *)[cell viewWithTag:202];
	label.text = mission.mPlace;
	
	label = (UILabel *)[cell viewWithTag:200];
	label.text = mission.mDescription;
	
	label = (UILabel *)[cell viewWithTag:203];
	label.text = [APPDEL toNSString:mission.mWriteDate :@"yyyy-MM-dd HH:mm:ss"];
    
    UIButton *button = (UIButton *)[cell viewWithTag:300];
    
    [button setBackgroundImage:[ImageManager loadBadgeImg:mission.mID] forState:UIControlStateNormal];
	
	return cell;
}



#pragma mark -
#pragma mark Table view delegate

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath{
	
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		//DB 삭제
		MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
		MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
		ItemQuizDao *itemQuizDao = [[[ItemQuizDao alloc] init] autorelease];
	    
		Mission *mission = [[APPDEL buildingMissions] objectAtIndex:indexPath.row];
		//MissionItem *missionItem =[[[MissionItem alloc] init] autorelease];
		
		[missionDao delete:mission];
		
		for ( int i = 0 ; i < [mission.mItems count]; i++ )
		{
			MissionItem *missionItem = [mission.mItems objectAtIndex:i];
            
			for (int j = 0; j < [missionItem.itemQuizzes count]; j++) 
				[itemQuizDao delete:[missionItem.itemQuizzes objectAtIndex:j]];
			
			
			[missionItemDao delete:missionItem];
		}
        
		[[APPDEL buildingMissions] removeObjectAtIndex:indexPath.row];
		[self.tableView reloadData];
	}
	
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    
    Mission *mission = [[APPDEL buildingMissions] objectAtIndex:alertView.tag];
    
    if(buttonIndex == 1)
    {
        MissionBuilder *missionBuilder = [[[MissionBuilder alloc] initWithNibName:@"MissionBuilder" bundle: [NSBundle mainBundle]] autorelease];
        missionBuilder.mission = [[APPDEL buildingMissions] objectAtIndex:alertView.tag];
        missionBuilder.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:missionBuilder animated:YES];
        [missionBuilder loadBulidingMission];  
    }
    
    //테스트
    else if(buttonIndex == 2) {
        NSDictionary *tempDic = [[[NSDictionary alloc] initWithObjectsAndKeys:mission.mID,@"MissionID",
                                  mission.mTitle,@"Title",
                                  mission.mDescription,@"Description",
                                  mission.mPlace,@"Place",
                                  @"0",@"PlayCnt",
                                  @"0.0",@"RecommendAvg",
                                  @"",@"ShortUser1",
                                  @"",@"ShortRecord1",nil] autorelease];
        
        
        MissionListDetailController *missionListDetailController = [[[MissionListDetailController alloc] initWithNibName:@"MissionListDetailController" bundle: [NSBundle mainBundle]] autorelease];
        missionListDetailController.missionDic = tempDic;
        missionListDetailController.isTest = true;
        
        [self.navigationController pushViewController:missionListDetailController animated:YES];   
    }
    
    //서버업로드
    else if(buttonIndex == 3) {
        [self uploadServer:mission];
        uMission = mission;
        
        NSDictionary *tempDic = [[[NSDictionary alloc] initWithObjectsAndKeys:mission.mID,@"MissionID",
                                  mission.mTitle,@"Title",
                                  mission.mDescription,@"Description",
                                  mission.mPlace,@"Place",
                                  @"0",@"PlayCnt",
                                  @"0.0",@"RecommendAvg",
                                  @"",@"ShortUser1",
                                  @"",@"ShortRecord1",nil] autorelease];
        [[APPDEL designedArray] addObject:tempDic];
        
        
        
    }
    
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	/**** 운영용 이다 ***/
    Mission *mission = [[APPDEL buildingMissions] objectAtIndex:indexPath.row];
    
    
     if (mission.mStatus == DESIGNING) {
     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"builer_list_pop1", nil)
     message:NSLocalizedString(@"builer_list_pop2", nil)
     delegate:self 
     cancelButtonTitle:NSLocalizedString(@"cancel", nil) 
     otherButtonTitles:NSLocalizedString(@"builer_list_pop3", nil),NSLocalizedString(@"builer_list_pop4", nil),nil];
     
     
     alertView.tag = indexPath.row;
     [alertView show];
     [alertView release];
     
     }
     else if (mission.mStatus == TESTED)
     {
     
     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"builer_list_pop11", nil)
     message:NSLocalizedString(@"builer_list_pop12", nil)
     delegate:self 
     cancelButtonTitle:NSLocalizedString(@"cancel", nil) 
     otherButtonTitles:NSLocalizedString(@"builer_list_pop13", nil),NSLocalizedString(@"builer_list_pop4", nil),NSLocalizedString(@"builer_list_pop14", nil),nil];
     
     
     alertView.tag = indexPath.row;
     [alertView show];
     [alertView release];
     
     }
     /***  운영용이다 End   ***/
    
    /* //테스트 용이다 올릴때는 위에꺼 풀어라
 	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"builer_list_pop11", nil)
                                                        message:NSLocalizedString(@"builer_list_pop12", nil)
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"cancel", nil) 
                                              otherButtonTitles:NSLocalizedString(@"builer_list_pop13", nil),NSLocalizedString(@"builer_list_pop4", nil),NSLocalizedString(@"builer_list_pop14", nil),nil];
    
    
    alertView.tag = indexPath.row;
    [alertView show];
    [alertView release];
    */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [uMission release]; uMission =nil;
    [tableView release]; tableView = nil;
}


- (void)dealloc {
    
    [uMission release]; 
    [tableView release];
    [super dealloc];
}


@end

