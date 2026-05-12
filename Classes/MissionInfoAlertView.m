//
//  MissionInfoAlertView.m
//  TreasureHunter
//
//  Created by  on 12. 7. 2..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "MissionInfoAlertView.h"
#import "TreasureHunterAppDelegate.h"

@implementation MissionInfoAlertView
@synthesize tableView;

- (id) initWithTitle:(NSString *)title
			delegate:(id)delegate 
   cancelButtonTitle:(NSString *)cancelButtonTitle 
   otherButtonTitles:(NSString *)otherButtonTitles
          missionDic:(NSDictionary *)mDic
                quiz:(NSString *)mQuiz
               hints:(NSArray *)hintList
               items:(NSArray*)itemList{
    
    self = [super initWithTitle:title
						message:@"\n\n\n\n\n\n\n\n\n\n\n\n" 
					   delegate:delegate
			  cancelButtonTitle:cancelButtonTitle 
			  otherButtonTitles:otherButtonTitles, nil];
    missionDic = mDic;
    missionQuiz = mQuiz;
    hintArray = hintList;
    itemArray = itemList;
    
    NSArray *titleArray = [[[NSArray alloc] initWithObjects:NSLocalizedString(@"m_info_alert_0", nil),NSLocalizedString(@"m_info_alert_1", nil),NSLocalizedString(@"m_info_alert_2", nil),NSLocalizedString(@"m_info_alert_3", nil),NSLocalizedString(@"m_info_alert_4", nil),NSLocalizedString(@"m_info_alert_5", nil),nil] autorelease];
    tempTitleArray = [[NSMutableArray alloc] init];
    
    
    stringArray = [[NSMutableArray alloc] init];
    listSizeArray = [[NSMutableArray alloc] init];
    
    
    [stringArray addObject:[missionDic objectForKey:@"Title"]];
    [stringArray addObject:[missionDic objectForKey:@"Description"]];
    [listSizeArray addObject:[NSNumber numberWithInt:1]];
    [listSizeArray addObject:[NSNumber numberWithInt:1]];
    [tempTitleArray addObject:[titleArray objectAtIndex:0]];
    [tempTitleArray addObject:[titleArray objectAtIndex:1]];
    
    if(![self stringIsEmpty:[missionDic objectForKey:@"ShortUser1"]]){
        [tempTitleArray addObject:[titleArray objectAtIndex:2]];
        [listSizeArray addObject:[NSNumber numberWithInt:1]];
        [stringArray addObject:[NSString stringWithFormat:@"%@ : %@", [self trimUserID:[missionDic objectForKey:@"ShortUser1"]],[missionDic objectForKey:@"ShortRecord1"]]];
    }
    
    if(![self stringIsEmpty:missionQuiz]){
        [tempTitleArray addObject:[titleArray objectAtIndex:3]];
        [listSizeArray addObject:[NSNumber numberWithInt:1]];
        [stringArray addObject:missionQuiz];
    }
    if([hintArray count] > 0){
        [tempTitleArray addObject:[titleArray objectAtIndex:4]];
        [listSizeArray addObject:[NSNumber numberWithInt:[hintArray count]]];
        [stringArray addObjectsFromArray:hintArray];
    }
    
    if([itemArray count] > 0){
        [tempTitleArray addObject:[titleArray objectAtIndex:5]];
        [listSizeArray addObject:[NSNumber numberWithInt:[itemArray count]]];
        [stringArray addObjectsFromArray:itemArray];
    }
    
    tableView = [[UITableView alloc] initWithFrame:CGRectMake(11, 50, 261, 240)];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self addSubview:tableView];
    
    return self;
}


- (NSString *)trimUserID:(NSString*)userId{
    NSRange subRange;
    subRange = [userId rangeOfString : @"@"];
    if(subRange.location == NSNotFound){
        return userId;
    }
    return [userId substringToIndex : subRange.location];   
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




- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [listSizeArray count]; 
}


- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    int retInt = 0;
    if(section < [listSizeArray count]){
        retInt =  [[listSizeArray objectAtIndex:section] intValue];
    }
    return retInt;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *retString = @"미션 정보";
    if(section < [tempTitleArray count]){
        retString = [tempTitleArray objectAtIndex:section];
    }
    return retString;    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat labelHeight = 32;
    
    UILabel *myLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 400)] autorelease];
    myLabel.numberOfLines = 0;
    myLabel.lineBreakMode = UILineBreakModeWordWrap;
    myLabel.text = [self stringWithSectionRow:indexPath.section Row:indexPath.row];
    CGSize labelSize = [myLabel.text sizeWithFont:myLabel.font 
                                constrainedToSize:myLabel.frame.size 
                                    lineBreakMode:UILineBreakModeWordWrap];
    labelHeight = labelSize.height+30;
    
    if(labelHeight <32){
        labelHeight = 32;
    }
    return labelHeight;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] init] autorelease];
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.text = [self stringWithSectionRow:indexPath.section Row:indexPath.row];
    
    NSLog(@"cell.textLabel.text:%d,%d,%@",indexPath.section,indexPath.row, cell.textLabel.text);
    
    return cell;
}

- (NSString *) stringWithSectionRow:(int)section Row:(int)row{
    int temp = 0;
    
    if(section <[listSizeArray count]){
        for(int i = 0; i< section ; i++){
            temp += [[listSizeArray objectAtIndex:i] intValue];
        }
    }else{
        return @"";
    }
    
    if(temp+row<[stringArray count]){
        return [stringArray objectAtIndex:temp +row];
    }
    return @"";
}


- (void)dealloc {
    [tableView release]; tableView = nil;
    [tempTitleArray release]; tempTitleArray = nil;
    [stringArray release]; stringArray = nil;
    [listSizeArray release]; listSizeArray = nil;

    [super dealloc];
}



@end
