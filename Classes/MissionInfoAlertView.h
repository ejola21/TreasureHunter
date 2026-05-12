//
//  MissionInfoAlertView.h
//  TreasureHunter
//
//  Created by  on 12. 7. 2..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MissionInfoAlertView : UIAlertView<UITableViewDelegate, UITableViewDataSource>
{
    UITableView *tableView;
    NSDictionary *missionDic;
    NSString *missionQuiz;
    NSArray *hintArray;
    NSMutableArray *stringArray;
    NSArray *itemArray;
    NSMutableArray *listSizeArray;
    NSMutableArray *tempTitleArray;
}

@property (nonatomic,retain) UITableView *tableView;

- (id) initWithTitle:(NSString *)title
			delegate:(id)delegate 
   cancelButtonTitle:(NSString *)cancelButtonTitle 
   otherButtonTitles:(NSString *)otherButtonTitles
          missionDic:(NSDictionary *)mDic
                quiz:(NSString *)mQuiz
               hints:(NSArray *)hintList
               items:(NSArray*)itemList;

- (NSString *) stringWithSectionRow:(int)section Row:(int)row;
@end


