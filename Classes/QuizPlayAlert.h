//
//  QuizPlayAlert.h
//  TreasureHunter
//
//  Created by  on 12. 6. 12..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MissionItem.h"
#import "ItemQuiz.h"
#import "TreasureHunterAppDelegate.h"
#import <StoreKit/StoreKit.h>

// alert tag
#define	ALERT_SOLUTION	100
#define	ALERT_SOLUTION_ITEM	101
#define	ALERT_FAIL      200
#define	ALERT_SUCCESS   300
@class ARViewController;

@interface QuizPlayAlert : UIAlertView<SKPaymentTransactionObserver>{
    UIImage *backgroundImage;
    
    UIButton * homeButton;
    UIButton * solutionButton;
    
    UILabel *questionView;
    UITextField *answerField;
    UILabel *hintLabel;
	
	MissionItem *missionItem;
	ItemQuiz *quizItem;
	ARViewController *caller;
	CGPoint svos;
	int failCnt;
	int timerCnt;
        UIImageView *ArIconView;

    BOOL onBuy;
@private

	int quizSeq;
    
    
    
}
@property(readwrite, retain) UIImage *backgroundImage;
@property (nonatomic, retain) ARViewController *caller;

- (id) initWithItem:(MissionItem *)getMissionItem
               cell:(ARViewController *)getCaller;
- (void)failQuiz;
@end
