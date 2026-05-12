//
//  Bulletin.m
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Bulletin.h"
#import "SVProgressHUD.h"
#import "HTTPRequest.h"
#import "JSON.h"
#import "TreasureHunterAppDelegate.h"
#import "ImageManager.h"
@implementation Bulletin
@synthesize tableView;
@synthesize navigationItem;
@synthesize naviBar;

#pragma mark -
#pragma mark Life Cycle Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    playedImgArray = [[NSMutableArray alloc] initWithObjects:@"play01.png",@"play02.png",@"play03.png",@"play04.png",@"play05.png",@"play06.png",@"play07.png",@"play08.png", @"play09.png",@"play10.png",@"play11.png",@"play12.png", @"play01.png",@"play02.png",@"play03.png",@"play04.png",@"play05.png",@"play06.png",@"play07.png",@"play08.png", @"play09.png",@"play10.png",@"play11.png",@"play12.png",nil] ;
    designedImgArray = [[NSMutableArray alloc] initWithObjects:@"mission01.png",@"mission02.png",@"mission03.png",@"mission04.png",@"mission05.png",@"mission06.png",@"mission07.png",@"mission08.png", @"mission09.png",@"mission10.png",@"mission11.png",@"mission12.png", nil] ;
    
    
    CGRect tableViewFrame = CGRectMake(0.0, 44.0, self.view.bounds.size.width, self.view.bounds.size.height - 44 );
    tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorColor = [UIColor clearColor];
    [tableView setAllowsSelection:false];
    
    [self.view addSubview:tableView];
    
    [self.navigationItem setTitle:NSLocalizedString(@"bulletin_title", nil)];
    [self.naviBar setTintColor:[APPDEL backColor]];
    if([APPDEL designCount] < 0){
        [self httpSend:0];
    }
    if([APPDEL playedCount] < 0){
        [self httpSend:1];
    }
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [SVProgressHUD dismiss];
}

- (void)viewDidUnload {
    [self setNaviBar:nil];
    [self setNavigationItem:nil];
    
    
    [playedImgArray release];
    [designedImgArray release];
    
}


- (void)dealloc {
    [playedImgArray release];
    [designedImgArray release];
    [tableView release];
    
    [navigationItem release];
    [naviBar release];
    [super dealloc];
}


#pragma mark -
#pragma mark HTTP Functions

- (void)httpSend:(int) getKind
{
    [SVProgressHUD showWithStatus:@"Loading.."];
    NSLog(@"inside loading");
    //600 / 601
    NSString *tr = @"600"; //design
    if(getKind == 1){
        tr = @"601"; //plsy
    }
    
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                tr,@"tr",
                                [APPDEL gUserID],@"id", nil];
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
    if(getKind == 0){
        [httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];
    }else{
        [httpRequest setDelegate:self selector:@selector(didReceivePlayFinished:)];
    }
	// 페이지 호출
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
    
}

- (void)didReceiveFinished:(NSString *)result
{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        
        [[APPDEL designedArray] removeAllObjects]; 
        if(svrArr !=nil){
            [[APPDEL designedArray] addObjectsFromArray:svrArr]; 
            [APPDEL setDesignCount:[[APPDEL designedArray] count]];
            for(int i = 0 ; i < [APPDEL designCount]; i++){
                [APPDEL checkNAddDesignImg:[[[APPDEL designedArray] objectAtIndex:i]objectForKey:@"MissionID"]];
            }
        }else{
            [APPDEL setDesignCount:0];
        }
    }
    [tableView reloadData];
    [SVProgressHUD dismiss];
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
            for(int i = 0 ; i < [APPDEL playedCount]; i++){
                [APPDEL checkNAddImg:[[[APPDEL playedArray] objectAtIndex:i]objectForKey:@"MissionID"]];
            }
        }else{
            [APPDEL setPlayedCount:0];
        }
    }
    [tableView reloadData];
    [SVProgressHUD dismiss];
}


#pragma mark -
#pragma mark Table View Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3; 
}


- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case 0:
            if([APPDEL playedCount] %3==0){
                return 1+([APPDEL playedCount]/3);
            }else{
                return 2+([APPDEL playedCount]/3);
            }
			break;
		case 1:
            return 7;
			break;
        case 2:
			return 5;
			break;
	}
    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat labelHeight = 32;
    
    if(indexPath.row == 0){
        labelHeight = 32;
    }else{
        labelHeight = 120;
    } 
    
    
    return labelHeight;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int row = indexPath.row;
    int section = indexPath.section;
    
	
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
		cell = [[[UITableViewCell alloc] init] autorelease];
    }
    
    if(section == 0) {
		if(row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            cell.textLabel.text = NSLocalizedString(@"mission_badge", nil);
		}else {      
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BadgeListCell" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL cellColor]];
            UILabel *label;
            UIButton *btn;
            UIImage *image;
            
            int LabelTag[] = {200,201,202};
            int btnTag[] = {100,101,102};
            int location[] = {(row-1)*3,(row-1)*3+1,(row-1)*3+2};
            
            for(int i = 0; i < 3; i++){
                label = (UILabel *)[cell viewWithTag:LabelTag[i]];
                if(location[i] < [APPDEL playedCount]){
                    label.text = [[[APPDEL playedArray] objectAtIndex:location[i]]objectForKey:@"Title"];
                    image = [[APPDEL playedImg] objectForKey:[[[APPDEL playedArray] objectAtIndex:location[i]]objectForKey:@"MissionID"]];  
                }else{
                    label.text = @"";
                    image = [UIImage imageNamed:@"empty02.png"];
                }
                if(image == nil){
                    image = [UIImage imageNamed:@"empty02.png"];
                }
                
                btn = (UIButton *)[cell viewWithTag:btnTag[i]];
                [btn setBackgroundImage:image forState:UIControlStateNormal];
                [btn setTag:100+location[i]];
                [btn addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];  
                
            }
            
		}
    }else if(section == 1) {
		if(row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            cell.textLabel.text =NSLocalizedString(@"play_badge", nil);
		}else {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BadgeListCell" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL cellColor]];
            UILabel *label;
            UIButton *btn;
            UIImage *image;
            
            int playArray[] = {5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,90,100};
            int LabelTag[] = {200,201,202};
            int btnTag[] = {100,101,102};
            int location[] = {(row-1)*3,(row-1)*3+1,(row-1)*3+2};
            
            for(int i = 0; i < 3; i++){
                label = (UILabel *)[cell viewWithTag:LabelTag[i]];
                label.text = [NSString stringWithFormat:@"%d Played", playArray[location[i]]];
                
                if([self showBadge:location[i] badgeKind:2]){
                    image = [UIImage imageNamed:[NSString stringWithFormat:@"play%d",playArray[location[i]]]];
                }else{
                    image = [UIImage imageNamed:@"empty02.png"];
                }
                btn = (UIButton *)[cell viewWithTag:btnTag[i]];
                [btn setBackgroundImage:image forState:UIControlStateNormal];
                [btn setTag:200+location[i]];
                [btn addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];  
                
            }
		}
    }else if(section == 2) {
		if(row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            cell.textLabel.text = NSLocalizedString(@"desig_badge", nil);
		}else {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"BadgeListCell" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL cellColor]];
            
            UILabel *label;
            UIButton *btn;
            UIImage *image;
            
            int designArray[] = {1,5,10,15,20,25,30,35,40,45,50,60};
            int LabelTag[] = {200,201,202};
            int btnTag[] = {100,101,102};
            int location[] = {(row-1)*3,(row-1)*3+1,(row-1)*3+2};
            
            for(int i = 0; i < 3; i++){
                label = (UILabel *)[cell viewWithTag:LabelTag[i]];
                label.text = [NSString stringWithFormat:@"%d Designed", designArray[location[i]]];
                
                if([self showBadge:location[i] badgeKind:3]){
                    image = [UIImage imageNamed:[NSString stringWithFormat:@"design%d",designArray[location[i]]]];
                }else{
                    image = [UIImage imageNamed:@"empty02.png"];
                }
                btn = (UIButton *)[cell viewWithTag:btnTag[i]];
                [btn setBackgroundImage:image forState:UIControlStateNormal];
                [btn setTag:300+location[i]];
                [btn addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];    
            }
		}
    }
    return cell;
}

#pragma mark -
#pragma mark EX Functions



- (BOOL)showBadge:(int)loc badgeKind:(int)kind{
    int playArray[] = {5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,90,100};
    int designArray[] = {1,5,10,15,20,25,30,35,40,45,50,60};
    if(kind == 1){
        if(loc < [APPDEL playedCount]){
            return true;
        }else{
            return false;
        }
    }else if(kind == 2){
        if(playArray[loc]<= [APPDEL playedCount]){
            return true;
        }else{
            return false;
        }
    }else if(kind == 3){
        if(designArray[loc]<= [APPDEL designCount]){
            return true;
        }else{
            return false;
        }
    }
    
    return false;
}





#pragma mark -
#pragma mark UI Functions

- (void)onClick:(id) sender
{
    int playArray[] = {5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,90,100};
    int designArray[] = {1,5,10,15,20,25,30,35,40,45,50,60};
    
    UIButton *button = (UIButton *)sender;
    int btnId = button.tag;
    int badgeKind = btnId/100;
    int badgeLoc = btnId%100;
    
    NSString *title = @"";
    NSString *message = @"";
    
    if([self showBadge:badgeLoc badgeKind:badgeKind]){
        title = NSLocalizedString(@"obtain_badge", nil);
        if(badgeKind == 1){
            message = [NSString stringWithFormat:@"%@ %@",[[[APPDEL playedArray] objectAtIndex:badgeLoc]objectForKey:@"Title"],
                       NSLocalizedString(@"obtain_badge_success_message_0", nil)];
        }else if(badgeKind == 2){
            message = [NSString stringWithFormat:@"%d %@",playArray[badgeLoc],
                       NSLocalizedString(@"obtain_badge_success_message_1", nil)];
        }else if(badgeKind ==3){
            message = [NSString stringWithFormat:@"%d %@",designArray[badgeLoc],
                       NSLocalizedString(@"obtain_badge_success_message_2", nil)];
        }
    }else{
        title = NSLocalizedString(@"obtain_badge_fail", nil);
        if(badgeKind == 1){
            message = NSLocalizedString(@"obtain_badge_fail_message_0", nil);
        }else if(badgeKind == 2){
            message = [NSString stringWithFormat:NSLocalizedString(@"obtain_badge_fail_message_2", nil),playArray[badgeLoc]];
        }else if(badgeKind ==3){
            message = [NSString stringWithFormat:NSLocalizedString(@"obtain_badge_fail_message_3", nil),designArray[badgeLoc]];
        }
    }
    
    UIAlertView *alertView  = [[UIAlertView alloc] initWithTitle:title 
                                                         message:message 
                                                        delegate:nil 
                                               cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                               otherButtonTitles:nil];
    [alertView show];
    [alertView release]; 
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
