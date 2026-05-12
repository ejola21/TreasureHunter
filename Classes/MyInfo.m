//
//  MyInfo.m
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyInfo.h"
#import "TreasureHunterAppDelegate.h"
#import "HTTPRequest.h"
#import "JSON.h"
#import "SVProgressHUD.h"
#import "MissionListDetailController.h"
#import "DLStarRatingControl.h"
#import "ImageManager.h"

@implementation MyInfo
@synthesize tableView;
@synthesize navigationItem;
@synthesize naviBar;

#pragma mark -
#pragma mark Life cycle Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect tableViewFrame = CGRectMake(0.0, 44.0, self.view.bounds.size.width, self.view.bounds.size.height - 44 );
    tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    tableView.delegate = self;
    tableView.dataSource = self;
    
    [self.view addSubview:tableView];
    
    [self.navigationItem setTitle:NSLocalizedString(@"my_title", nil)];
    [self.naviBar setTintColor:[APPDEL backColor]];
    if([APPDEL playedCount] < 0){
        [self httpSend:1];   
    }    
    if([APPDEL designCount] < 0){
        [self httpSend:0]; 
    }
    onBuy = false;
    if ([SKPaymentQueue canMakePayments]) {	
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];	// Observer를 등록한다.
    }
    
    
}

- (void) viewWillAppear:(BOOL)animated{
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [SVProgressHUD dismiss];
}

#pragma mark -
#pragma mark Http Connect Functions


- (void)httpSend:(int) getKind
{
    NSLog(@"inside loading myinfo");
    [SVProgressHUD showWithStatus:@"Loading.."];
    
    NSString *tr = @"600";
    if(getKind == 1){
        tr = @"601";
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
            for(int i = 0 ; i < [APPDEL playedCount] ; i++){
                [APPDEL checkNAddImg:[[[APPDEL playedArray] objectAtIndex:i]objectForKey:@"MissionID"]];
            }
        }else{
            [APPDEL setPlayedCount:0];
        }
    }
    [tableView reloadData];
    [SVProgressHUD dismiss];
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



#pragma mark -
#pragma mark TableView Functions


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4; 
}


- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case 0:
			return 2;
			break;
        case 1:    
            return 3;
            break;
		case 2:
            return [APPDEL designCount]+1;
			break;
        case 3:
			return [APPDEL playedCount]+1;
			break;
	}
    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat labelHeight = 32;
    if(indexPath.section == 0){
        labelHeight = 32;
    }else if(indexPath.section == 1){
        if(indexPath.row == 0){
            labelHeight = 32;
        }else {
            labelHeight = 40;   
        }
    }else{
        if(indexPath.row == 0){
            labelHeight = 32;
        }else{
            labelHeight = 100;
        } 
    }
    
    return labelHeight;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
	
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
		cell = [[[UITableViewCell alloc] init] autorelease];
    }
    
    if(indexPath.section == 0) {
		if(indexPath.row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            cell.textLabel.text = NSLocalizedString(@"user_id", nil);
		}else {
            [cell setBackgroundColor:[APPDEL cellColor]];
			cell.textLabel.text = [APPDEL gUserID];
		}
    }else if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            cell.textLabel.text = NSLocalizedString(@"my_info_0", nil);
		}else {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoCellB" owner:self options:nil] objectAtIndex:0];
            UILabel *label;
            label = (UILabel *)[cell viewWithTag:2];
            if(indexPath.row == 1){
                label.text = NSLocalizedString(@"my_info_1", nil);
            }else{
                label.text = NSLocalizedString(@"my_info_2", nil);
            }
            label = (UILabel *)[cell viewWithTag:1];
            if(indexPath.row == 1){
                if ([APPDEL timeAddCount] == 0) {
                    label.text = NSLocalizedString(@"my_info_4", nil);
                }else {
                    label.text = [NSString stringWithFormat:NSLocalizedString(@"my_info_3", nil), [APPDEL timeAddCount]]; 
                }
            }else{
                if ([APPDEL solutionCount] == 0) {
                    label.text = NSLocalizedString(@"my_info_4", nil);
                }else {
                    label.text = [NSString stringWithFormat:NSLocalizedString(@"my_info_3", nil), [APPDEL solutionCount]];
                }
            }         
		}      
    }else if(indexPath.section == 2){
		if(indexPath.row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            cell.textLabel.text = NSLocalizedString(@"design_mission", nil);
		}else {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoCell" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL cellColor]];
            DLStarRatingControl *customNumberOfStars = [[[DLStarRatingControl alloc] initWithFrame:CGRectMake(0, 0, 110, 25) andStars:5 isFractional:true setSize0to20:15 clickEnabled:false] autorelease];
            customNumberOfStars.rating = 2.5;
            
            UIView *starView = (UIView *)[cell viewWithTag:100];
            [starView addSubview:customNumberOfStars];
            
            if(indexPath.row <= [APPDEL designCount]){
                NSDictionary *dic = [[APPDEL designedArray] objectAtIndex:indexPath.row-1];
                
                
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
                
                UIImage *image = [[APPDEL designedImg] objectForKey:[dic objectForKey:@"MissionID"]];  
                
                
                
                
                if(image == nil){
                    image = [UIImage imageNamed:@"empty02.png"];
                }
                [button setBackgroundImage:image forState:UIControlStateNormal];
            }
		}
    }else if(indexPath.section == 3) {
		if(indexPath.row == 0) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoList" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL backColor]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            cell.textLabel.text = NSLocalizedString(@"play_mission", nil);
		}else {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"MyInfoCell" owner:self options:nil] objectAtIndex:0];
            [cell setBackgroundColor:[APPDEL cellColor]];
            
            DLStarRatingControl *customNumberOfStars = [[[DLStarRatingControl alloc] initWithFrame:CGRectMake(0, 0, 110, 25) andStars:5 isFractional:true setSize0to20:15 clickEnabled:false] autorelease];
            customNumberOfStars.rating = 2.5;
            
            UIView *starView = (UIView *)[cell viewWithTag:100];
            [starView addSubview:customNumberOfStars];
            
            
            if(indexPath.row <= [APPDEL playedCount]){
                NSDictionary *dic = [[APPDEL playedArray] objectAtIndex:indexPath.row-1];
                
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
                
                UIImage *image = [[APPDEL playedImg] objectForKey:[dic objectForKey:@"MissionID"]];  
                
                
                BOOL isReal = false;
                BOOL isFirst = false;
                if([[dic objectForKey:@"isVirtual"] intValue] == REAL_MODE){
                    isReal = true;
                }
                
                if(![self stringIsEmpty:[dic objectForKey:@"ShortUser1"]] ){
                    if([[dic objectForKey:@"ShortUser1"] isEqualToString:[APPDEL gUserID]]){
                        isFirst = true;
                    }
                }
                if(image == nil){
                    image = [UIImage imageNamed:@"empty02.png"];
                }else if(isReal && isFirst){
                    image = [ImageManager ImageMergeTitle:image Kind:2];
                }else if(isReal){
                    image = [ImageManager ImageMergeTitle:image Kind:1];
                }else if(isFirst){
                    image = [ImageManager ImageMergeTitle:image Kind:0];
                }
                [button setBackgroundImage:image forState:UIControlStateNormal];
            }
		}
    }
    //[cell setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:1 alpha:0.5]];
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	int section = newIndexPath.section;
    int row = newIndexPath.row;
    
    
    if (section== 0 || row == 0) {	
		return;
    }
    if(section == 1 && !onBuy){
        if(row == 1){
            timeBuy = true;
            [self startPayment:@"time_add_10"];
            
        }else if(row == 2){
            timeBuy = false;
            [self startPayment:@"solution_add_10"];
        }
    }else if(section == 2){
        if(row <= [APPDEL designCount]){           
            MissionListDetailController *missionListDetailController = [[[MissionListDetailController alloc] initWithNibName:@"MissionListDetailController" bundle: [NSBundle mainBundle]] autorelease];
            
            missionListDetailController.missionDic = [[APPDEL designedArray] objectAtIndex:row-1];
            missionListDetailController.isTest = false;
            [self.navigationController pushViewController:missionListDetailController animated:YES];
        }
    }else if(section == 3){
        if(row <= [APPDEL playedCount]){
            // NSDictionary *dic = [[APPDEL playedArray] objectAtIndex:row-1];
            
            MissionListDetailController *missionListDetailController = [[[MissionListDetailController alloc] initWithNibName:@"MissionListDetailController" bundle: [NSBundle mainBundle]] autorelease];
            
            missionListDetailController.missionDic =  [[APPDEL playedArray] objectAtIndex:row-1];
            missionListDetailController.isTest = false;
            [self.navigationController pushViewController:missionListDetailController animated:YES];
        }
    }
    
}

#pragma mark -
#pragma mark Payment Functions

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	if( [response.products count] > 0 ) {
        onBuy = true;
        [SVProgressHUD showWithStatus:NSLocalizedString(@"purchase", nil)];
		SKProduct *product = [response.products objectAtIndex:0];
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
	}
}


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
    [self payAlert];
    [SVProgressHUD dismiss];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
- (void) resultbuy{
    if(timeBuy){
        [APPDEL setTimeAddCount:10+ [APPDEL timeAddCount]];
    }else{
        [APPDEL setSolutionCount:10+ [APPDEL solutionCount]];
    }
    
    [tableView reloadData];
}

- (void) payAlert{
    if(onBuy){
        onBuy = false;
        UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:NSLocalizedString(@"purchase_0", nil)
                                  message:NSLocalizedString(@"purchase_1", nil)
                                  delegate:self 
                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        [alertView release]; 
    }
    
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
#pragma mark End Life cycle Functions


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [self setNaviBar:nil];
    [self setNavigationItem:nil];
    
}


- (void)dealloc {
    [tableView release];
    [navigationItem release];
    [naviBar release];
    [super dealloc];
}

@end
