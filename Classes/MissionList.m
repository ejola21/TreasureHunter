//
//  Bulletin.m
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MissionList.h"
#import "TreasureHunterAppDelegate.h"
#import "Mission.h"
#import "HTTPRequest.h"
#import "JSON.h"
#import "MissionDao.h"
#import "MissionItemDao.h"
#import "ItemQuizDao.h"
#import "MissionPlay.h"
#import "MissionInPlayDao.h"
#import "MissionItemInPlayDao.h"
#import "MissionInPlay.h"
#import "MissionListDetailController.h"
#import "SVProgressHUD.h"
#import "DLStarRatingControl.h"
#import "ImageManager.h"
#import "Login.h"

@implementation MissionList
@synthesize tableView;
@synthesize segmenteControl;
@synthesize naviBar;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    gameList = [[NSMutableArray alloc] init];
    
    imgArray = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"playing1.png"],[UIImage imageNamed:@"playing2.png"],[UIImage imageNamed:@"playing3.png"],[UIImage imageNamed:@"playing5.png"],[UIImage imageNamed:@"playing4.png"], nil];

    CGRect tableViewFrame = CGRectMake(0.0, 44.0, self.view.bounds.size.width, self.view.bounds.size.height - 44 );
    tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    tableView.delegate = self;
    tableView.dataSource = self;
    
    UIImage *image = [UIImage imageNamed:@"loginbg_botton@2x.png"]; 
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
    imageView.alpha =0.3;
    
    [self.view addSubview:tableView];
    [self.segmenteControl setTitle:NSLocalizedString(@"m_list_0", nil) forSegmentAtIndex:0];
    [self.segmenteControl setTitle:NSLocalizedString(@"m_list_1", nil) forSegmentAtIndex:1];
    [self.segmenteControl setTitle:NSLocalizedString(@"m_list_2", nil) forSegmentAtIndex:2];
    [self.naviBar setTintColor:[APPDEL backColor]];
    
    last = 0;
    tabKind = 0;
    playCount = 0;
    
    if(![[APPDEL gUserID] isEqualToString:[APPDEL guestUserID]]){
        [self playedHttpSend];
    }
    [self getList:tabKind];
}

- (void)viewWillAppear:(BOOL)animated{
    last = 0;
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self loadingFinish];
}

- (void)loadingStart{
    [SVProgressHUD showWithStatus:@"Loading.."];
    segmenteControl.userInteractionEnabled = false;
    tableView.userInteractionEnabled = false;
    
}

- (void)loadingFinish{
    segmenteControl.userInteractionEnabled = true;
    tableView.userInteractionEnabled = true;
    [SVProgressHUD dismiss];
}

#pragma mark -
#pragma mark Http Load Functions

- (void)getList:(int) kind{
    
    if(kind == 0){
        [self playingHttpSend];
    }else {
        [self listHttpSend:kind];
    }
}


- (void) playingHttpSend{
    [self loadingStart];
    
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"602",@"tr",
                                [APPDEL gUserID], @"id",
                                nil];  
    
    [httpRequest setDelegate:self selector:@selector(didReceivePlayingFinished:)];
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
}

- (void)didReceivePlayingFinished:(NSString *)result
{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        [gameList removeAllObjects];
        if(svrArr !=nil){
            [gameList addObjectsFromArray:svrArr]; 
            playCount = [gameList count];
        }else{
            playCount = 0;
        }
        
    }
    [self listHttpSend:0];
}

- (void)listHttpSend:(int) trNumber
{
    [self loadingStart];
    
    tabKind = trNumber;  
    if(tabKind != 0){
        playCount = 0;
    }
    
    NSString *tr;
    switch (trNumber) 
    {
        case 0: tr = @"500";  break; //playing
        case 1: tr = @"502";  break;
        case 2: tr = @"501";  break; 
    }
    
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
    NSDictionary *bodyObject;
    NSString *lati = [NSString stringWithFormat:@"%d",[APPDEL startPoint].coordinate.latitude];
    NSString *longi = [NSString stringWithFormat:@"%d",[APPDEL startPoint].coordinate.longitude];
    if(tabKind == 2){
        bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                      tr,@"tr",
                      [NSString stringWithFormat:@"%d",last], @"last",
                      [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0], @"lang",
                      lati,@"latitude",
                      longi,@"longitude",
                      nil];
    }else{
        bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                      tr,@"tr",
                      [NSString stringWithFormat:@"%d",last], @"last",
                      [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0], @"lang",
                      nil];
    }   
    
    [httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];   
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
}



- (void)didReceiveFinished:(NSString *)result
{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        
        if(last == 0 && tabKind != 0){
            [gameList removeAllObjects];
        }
        if(svrArr !=nil){
            [gameList addObjectsFromArray:svrArr]; 
        }
    }
    
    [tableView reloadData];
    [self loadingFinish];
}


- (void)playedHttpSend
{
    [self loadingStart];
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"601",@"tr",
                                [APPDEL gUserID],@"id", nil];
    [httpRequest setDelegate:self selector:@selector(didReceivePlayFinished:)];
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
    
}

- (void)didReceivePlayFinished:(NSString *)result
{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        
        [[APPDEL playedArray] removeAllObjects];
        if(svrArr !=nil){
            [[APPDEL playedArray] addObjectsFromArray:svrArr]; 
            [APPDEL setPlayedCount:[[APPDEL playedArray] count]];
            for(int i = 0 ; i <  [[APPDEL playedArray] count] ; i++){
                [APPDEL checkNAddImg:[[[APPDEL playedArray] objectAtIndex:i]objectForKey:@"MissionID"]];
            }
            [tableView reloadData];
        }else{
            [APPDEL setPlayedCount:0];
        }
    }
}



- (IBAction)segmentedChange:(id)sender {
    [tableView setContentOffset:CGPointMake(0, 0) animated:false];
    last = 0;
    [self getList:[sender selectedSegmentIndex]];
}


#pragma mark -
#pragma mark TableView Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if(tabKind == 0 && playCount > 0){
        return 2;
    }else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if(tabKind == 0 && playCount > 0){
        if(section == 0){
            return playCount;
        }else{
            return [gameList count] - playCount;
        }
    }
    return [gameList count];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    return 100;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(tabKind == 0 ){
        if(playCount > 0){
            switch (section) {
                case 0:
                    return NSLocalizedString(@"m_list_3", nil);
                    break;
                    
                default:
                    return NSLocalizedString(@"m_list_4", nil);
                    break;
            }
        }
        return NSLocalizedString(@"m_list_4", nil);
    }else if(tabKind == 1) {
        return NSLocalizedString(@"m_list_5", nil);
    }
    return NSLocalizedString(@"m_list_6", nil);
    
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int row = indexPath.row;
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"MissionListCell" owner:self options:nil] objectAtIndex:0];
    }
    
    
    [cell setBackgroundColor:[APPDEL cellColor]];
    
    DLStarRatingControl *customNumberOfStars = [[[DLStarRatingControl alloc] initWithFrame:CGRectMake(0, 0, 90, 25) andStars:5 isFractional:true setSize0to20:13 clickEnabled:false] autorelease];
    customNumberOfStars.rating = 2.5;
    
    UIView *starView = (UIView *)[cell viewWithTag:100];
    [starView addSubview:customNumberOfStars];
    
    if(row < [gameList count]){
        NSDictionary *dic;
        if(tabKind == 0 && playCount > 0){
            if(indexPath.section == 0){
                dic = [gameList objectAtIndex:row];
            }else if(indexPath.section == 1){
                dic = [gameList objectAtIndex:row+playCount];
            }
        }else{
            dic = [gameList objectAtIndex:row];
        }
        
        
        
        customNumberOfStars.rating = [[dic objectForKey:@"RecommendAvg"] floatValue];
        
        UILabel *label;
        label = (UILabel *)[cell viewWithTag:200];
        label.text = [dic objectForKey:@"Title"];
        
        label = (UILabel *)[cell viewWithTag:201];
        label.text = [dic objectForKey:@"Description"];
        
        label = (UILabel *)[cell viewWithTag:202];
        label.text = [dic objectForKey:@"Place"];
        
        label = (UILabel *)[cell viewWithTag:203];
        label.text = [NSString stringWithFormat:@"Play(%@) Fail(%@)", [dic objectForKey:@"PlayCnt"], [dic objectForKey:@"FailCnt"]];
        
        
        UIButton *button = (UIButton *)[cell viewWithTag:300];
        
        UIImage *img = [[APPDEL playedImg] objectForKey:[dic objectForKey:@"MissionID"]];
        
        if(img == nil){
            if(indexPath.section == 0 && row < playCount){
                img = [imgArray objectAtIndex:row%5];
            }else{
                img = [UIImage imageNamed:@"empty02.png"];
            }
        }
        [button setBackgroundImage:img forState:UIControlStateNormal];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
    int row = newIndexPath.row;
    if(row < [gameList count]){
        NSDictionary *dic;
        if(tabKind == 0 && playCount > 0){
            if(newIndexPath.section == 0){
                dic = [gameList objectAtIndex:row];
            }else if(newIndexPath.section == 1){
                dic = [gameList objectAtIndex:row+playCount];
            }
        }else{
            dic = [gameList objectAtIndex:row];
        }
        
        if([[APPDEL gUserID] isEqualToString:[APPDEL guestUserID]]){
            
            Login *user = [[Login alloc] init];
            user.listCaller = self;
            [self presentModalViewController:user animated:YES];
            [user release];
        }else{      
            MissionListDetailController *missionListDetailController = [[[MissionListDetailController alloc] initWithNibName:@"MissionListDetailController" bundle: [NSBundle mainBundle]] autorelease];
            
            missionListDetailController.missionDic = dic;
            missionListDetailController.isTest = false;
            missionListDetailController.listCaller = self;
            [self.navigationController pushViewController:missionListDetailController animated:YES];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (([scrollView contentOffset].y + scrollView.frame.size.height) == ([scrollView contentSize].height+3)) {
        last+= 30;
        [self listHttpSend:tabKind];
        return;
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


- (void)viewDidUnload {
    [gameList release];
    gameList = nil;
    [tableView release];
    tableView = nil;
    [segmenteControl release];
    segmenteControl = nil;
    [naviBar release];
    naviBar = nil;
}


- (void)dealloc {
    [gameList release];
    [tableView release];
    [segmenteControl release];
    [naviBar release];
    [super dealloc];
}
@end
