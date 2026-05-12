//
//  MissionPlayInfo.m
//  TreasureHunter
//
//  Created by ejola on 11. 6. 12..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MissionPlayInfo.h"
#import "TreasureHunterAppDelegate.h"
#import "MissionItemInPlayDao.h"
#import "ItemRnPInPlayDao.h"
#import "HTTPRequest.h"
#import "JSON.h"

@implementation MissionPlayInfo

@synthesize missionID;
@synthesize caller;

#pragma mark -
#pragma mark View lifecycle



- (void)viewDidLoad {
	[super viewDidLoad];
	
	
	
	tableList = [[NSMutableArray alloc] init];
	
	[self makeTableList];
	
}


/*
 - (void)viewWillAppear:(BOOL)animated {
 [super viewWillAppear:animated];
 }
 */
/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark -
#pragma mark User Func


- (void)makeTableList
{
	//ItemRnPInPlayDao *itemRnPInPlayDao = [[[ItemRnPInPlayDao alloc] init] autorelease];
	//NSMutableArray *AcquiredRnP = [itemRnPInPlayDao selectAcquiredRnP:self.missionID playerID:[APPDEL gUserID]];
    
	
	//만들때 null 이만들어질만한건 제일뒤로 빼라 
	[tableList removeAllObjects];
    
    NSMutableArray *data = [NSMutableArray arrayWithObjects:
                            [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"mission_info_0", nil)
                             ,@"title",caller.missionTitle,@"detail",nil],
                            [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"mission_info_1", nil)
                             ,@"title",caller.missionDesc,@"detail",nil],nil];
	
    [tableList addObject:
     [NSDictionary dictionaryWithObjectsAndKeys:
      NSLocalizedString(@"mission_info_2", nil),@"group",
      data,@"data",
      nil]
     ];
    
	//미션 퀴즈 추가
	if ([caller.missionQuiz length] > 0) 
	{
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"mission_info_3", nil),@"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys:caller.missionQuiz, @"detail",nil],
           nil],@"data",
          nil]
		 ];
	}
	
	//미션 제한 시간 
	if (caller.runLimitTime != nil && caller.runLimitTime != 0) {
		NSMutableArray *data = [NSMutableArray arrayWithObjects:
                                [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"mission_info_4", nil),@"title", 
                                 [APPDEL toNSString:caller.runLimitTime :@"HH:mm:ss"],@"detail",nil],
                                nil];
        
		[tableList addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"mission_info_5", nil),@"group",
          data,@"data",
          nil]
         ];
		
	}
	
	// 보유 아이템 
    /*
	if(AcquiredRnP != nil) {
		NSMutableArray *data = [[NSMutableArray alloc] initWithCapacity:0];
		
		for (NSMutableString *rnp in AcquiredRnP) {
			if([rnp compare:@"200"] == NSOrderedAscending)
				[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [[APPDEL rewardObjects] objectAtIndex:[[APPDEL rewardKeys] indexOfObject:rnp]],"title", nil]];
			else
				[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [[APPDEL penaltyObjects] objectAtIndex:[[APPDEL penaltyKeys] indexOfObject:rnp]],@"title", nil]];
		}
		
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"mission_info_6", nil),@"group",
          data,@"data",
          nil]
		 ];
		
		[data release];
	}
     */

	NSLog(@"tableList:%@", tableList);
    
    // 접속할 주소 설정
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/mission_play_info.php"] autorelease];
	
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정  
    // Dictionay 특성 조심 nil 이면 다음 항목 전송 안딤
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"c_mission_play_ranking",       @"tr",
                                self.missionID,           @"mission_id", 
                                nil];
	NSLog(@"bodyObject:%@",bodyObject);
    
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didSelMissionPlayRankingReceiveFinished:)];
	// 페이지 호출
	[httpRequest requestUrl:url bodyObject:bodyObject];
	//[indicator startAnimating];
    
}

- (void)didSelMissionPlayRankingReceiveFinished:(NSString *)result
{
    NSLog(@"result:%@:",result);
    if (![result isEqualToString:@" false"]) {
 		NSArray *svrArr;			
		SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        NSLog(@"svrArr:%@",svrArr);
        NSDictionary *dic = (NSDictionary *)svrArr;
        NSLog(@"ShortRecord1:%@:",[dic objectForKey:@"ShortRecord1"]);
        
        NSMutableArray *data = [NSMutableArray arrayWithObjects:
                                [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"mission_info_7", nil)
                                 ,@"title",[NSString stringWithFormat:@"%@ by %@",[dic objectForKey:@"ShortRecord1"],[dic objectForKey:@"ShortUser1"]],@"detail",nil],
                                [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"mission_info_8", nil)
                                 ,@"title",[NSString stringWithFormat:@"%@ by %@",[dic objectForKey:@"ShortRecord2"],[dic objectForKey:@"ShortUser2"]],@"detail",nil],
                                [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"mission_info_9", nil)
                                 ,@"title",[NSString stringWithFormat:@"%@ by %@",[dic objectForKey:@"ShortRecord3"],[dic objectForKey:@"ShortUser3"]],@"detail",nil],
                                nil];
        
        if([dic objectForKey:@"ShortRecord1"] != nil)
            [tableList addObject:
             [NSDictionary dictionaryWithObjectsAndKeys:
              NSLocalizedString(@"mission_info_10", nil),@"group",
              data,@"data",
              nil]
             ];
        
        [self.tableView reloadData];
    }
    else {
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ([tableList count] == 0 ? 1 : [tableList count]);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[tableList objectAtIndex:section] objectForKey:@"data"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	return [[tableList objectAtIndex:section] objectForKey:@"group"];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"Cell";
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
	}
    
	NSDictionary *group = [tableList objectAtIndex:indexPath.section];
	NSMutableArray *cells = [group objectForKey:@"data"];
	NSDictionary *oneCell = [cells objectAtIndex:indexPath.row];
	
	cell.textLabel.text = [oneCell objectForKey:@"title"];
	cell.detailTextLabel.text = [oneCell objectForKey:@"detail"];
	
	return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[super dealloc];
	//self.missionID = nil;
    [caller release];
	[tableList release];
    
}


@end

