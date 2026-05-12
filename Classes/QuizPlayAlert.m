//
//  QuizPlayAlert.m
//  TreasureHunter
//
//  Created by  on 12. 6. 12..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "QuizPlayAlert.h"
#import "MissionItemInPlayDao.h"
#import "MissionItemInPlay.h"
#import "ARViewController.h"
#import "MissionPlay.h"
#import "ItemRnPInPlayDao.h"
#import "ItemRnPInPlay.h"
#import <QuartzCore/QuartzCore.h>


@implementation QuizPlayAlert
@synthesize backgroundImage,caller;



- (id) initWithItem:(MissionItem *)getMissionItem
               cell:(ARViewController *)getCaller{
    
    missionItem = getMissionItem;
	self.caller = getCaller;
	
    self = [super init];
    self.backgroundImage = [UIImage imageNamed:@"popup1.png"];
    
    onBuy = false;
    
    UIButton *imgViewLogo = [[[UIButton alloc] init] autorelease];
    [imgViewLogo setBackgroundImage: [UIImage imageNamed:@"loginbg_icon.png"] forState:UIControlStateNormal];
    [imgViewLogo setFrame:CGRectMake(45, 5, 191, 46)];
    
    
    ArIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[APPDEL itemARFile:[NSMutableString stringWithString:I_QUIZ]]]];
    [ArIconView setFrame:CGRectMake(0, 0, 49, 56)];
    ArIconView.layer.contents = (id)ArIconView.image.CGImage;
    ArIconView.layer.bounds = CGRectMake(0, 0, ArIconView.image.size.width, ArIconView.image.size.height);
    ArIconView.layer.transform = CATransform3DMakeScale(1.50, 1.50, 1);
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation.autoreverses = YES;
    animation.duration = 0.35;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.repeatCount = HUGE_VALF;
    [ArIconView.layer addAnimation:animation forKey:@"pulseAnimation"];
    
    [imgViewLogo setFrame:CGRectMake(78, 5, 191, 46)];
    [self addSubview:ArIconView];
    
    
    
    questionView = [[UILabel alloc] initWithFrame:CGRectMake(11, 59, 258, 60)];
    questionView.textColor =  RGB(17, 52, 67);
    questionView.backgroundColor = [UIColor clearColor];
    questionView.font = [UIFont systemFontOfSize:18];
    questionView.numberOfLines = 0;
    questionView.lineBreakMode = UILineBreakModeWordWrap;
    [questionView setTextAlignment:UITextAlignmentCenter];
    
    hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 121, 258, 25)];
    hintLabel.textColor =  RGB(17, 52, 67);
    hintLabel.backgroundColor = [UIColor clearColor];
    hintLabel.font = [UIFont systemFontOfSize:16.0];
    
    answerField = [[UITextField alloc] initWithFrame:CGRectMake(11, 146, 258, 31)];
    answerField.textColor = [UIColor blackColor];
    [answerField setBorderStyle:UITextBorderStyleRoundedRect];
    
    homeButton = [[UIButton alloc] init];
    [homeButton addTarget:self action:@selector(homeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [homeButton setBackgroundImage:[UIImage imageNamed:@"loginbg_botton.png"] forState:UIControlStateNormal];
    [homeButton setTitle:NSLocalizedString(@"ok", nil) forState:UIControlStateNormal];
    [homeButton setFrame:CGRectMake(149, 180, 120, 33)];
    
    solutionButton = [[UIButton alloc] init];
    [solutionButton addTarget:self action:@selector(solutionSelect:) forControlEvents:UIControlEventTouchUpInside];
    [solutionButton setBackgroundImage:[UIImage imageNamed:@"loginbg_botton2.png"] forState:UIControlStateNormal];
    [solutionButton setFrame:CGRectMake(11, 180, 120, 33)];
    
    if ([[caller.caller.dicRnPTaken valueForKey:I_SOLUTION] intValue] > 0) {
        [solutionButton setTitle:NSLocalizedString(@"quiz_button_0", nil) forState:UIControlStateNormal];
    }else if([APPDEL solutionCount]){
        [solutionButton setTitle:NSLocalizedString(@"quiz_button_1", nil) forState:UIControlStateNormal];
    }else{
        [solutionButton setTitle:NSLocalizedString(@"quiz_button_2", nil) forState:UIControlStateNormal];
    }
    
    [self addSubview:imgViewLogo];
    [self addSubview:questionView];
    [self addSubview:hintLabel];
    [self addSubview:answerField];
    [self addSubview:homeButton];
    [self addSubview:solutionButton];
    
    MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
    MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                            selectWithPK:missionItem.missionID
                                            playerID:[APPDEL gUserID] itemID:missionItem.itemID];
    failCnt = missionItemInPlay.failCnt;
    
    
    if ([missionItem.itemType isEqualToString:I_END]) {
        quizSeq = 0;
        questionView.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_9", nil), caller.caller.missionQuiz];
        
        if(failCnt > 0) {
            
            if ([caller.caller.missionAnswer length] < 2) {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_0", nil),
                                  [caller.caller.missionAnswer length]];
            }
            else {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_1", nil),
                                  [caller.caller.missionAnswer length],
                                  [caller.caller.missionAnswer substringToIndex:1]];
            }
        }
        
    }else {
        quizSeq = arc4random() % [missionItem.itemQuizzes count];
        quizItem = [missionItem.itemQuizzes objectAtIndex:quizSeq];
        
        questionView.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_9", nil),quizItem.quiz];
        if(failCnt > 0) {
            
            if ([quizItem.answer length] < 2) {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_0", nil),
                                  [quizItem.answer length]];
            }
            else {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_1", nil),
                                  [quizItem.answer length],
                                  [quizItem.answer substringToIndex:1]];
            }
        }
        
    }
    
    
    if ([SKPaymentQueue canMakePayments]) {	
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];	// Observer를 등록한다.
    }
    
    return self;
}



- (void)solutionSelect:(id)sender
{
    [answerField resignFirstResponder];
    if ([[caller.caller.dicRnPTaken valueForKey:I_SOLUTION] intValue] > 0 && !onBuy) {
        [answerField resignFirstResponder];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"quiz_2", nil) 
                                                            message:NSLocalizedString(@"quiz_message_0", nil) 
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
        
        
        [alertView setTag:ALERT_SOLUTION];
        [alertView show];
        [alertView release];
    }else if([APPDEL solutionCount]>0 && !onBuy){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"quiz_2", nil) 
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"quiz_message_1", nil),[APPDEL solutionCount]] 
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
        
        
        [alertView setTag:ALERT_SOLUTION_ITEM];
        [alertView show];
        [alertView release];
    }else if(!onBuy){
        [self startPayment:@"solution_add_10"];
    }
}

- (void)homeSelect:(id)sender
{
    if(!onBuy){
        [answerField resignFirstResponder];
        
        UIAlertView *alertView;
        NSString *answer;
        
        if ([missionItem.itemType isEqualToString:I_END]) 
            answer = caller.caller.missionAnswer;
        else {
            answer = quizItem.answer;
        }
        
        if([[answerField.text lowercaseString] isEqualToString:[answer lowercaseString]]) {
            MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
            
            
            MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                    selectWithPK:missionItem.missionID
                                                    playerID:[APPDEL gUserID] itemID:missionItem.itemID];	
            missionItemInPlay.endYN = (NSMutableString *)@"Y";
            missionItemInPlay.endTime = [NSDate date];
            missionItemInPlay.quizSeq = quizSeq;
            [missionItemInPlayDao save:missionItemInPlay];
            [caller.caller.dicItemEnd setValue:@"Y" forKey:[NSString stringWithFormat:@"%d",missionItem.itemID]];
            
            [APPDEL playSystemSound:@"quiz_rightanswer"  fileType:@"mp3"];
            AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
            alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"quiz_4", nil)
                                                   message:NSLocalizedString(@"quiz_5", nil) 
                                                  delegate:self 
                                         cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                         otherButtonTitles:nil, nil];
            
            [alertView setTag:ALERT_SUCCESS];
        }
        else {
            MissionItemInPlayDao *missionItemInPlayDao = [[[MissionItemInPlayDao alloc] init] autorelease];
            MissionItemInPlay *missionItemInPlay = [missionItemInPlayDao 
                                                    selectWithPK:missionItem.missionID
                                                    playerID:[APPDEL gUserID] itemID:missionItem.itemID];
            
            missionItemInPlay.failCnt = ++failCnt;
            missionItemInPlay.endTime = [NSDate date];
            missionItemInPlay.quizSeq = quizSeq;
            
            missionItemInPlay.endYN = (NSMutableString *)@"N";
            [caller.caller.dicItemEnd setValue:@"N" forKey:[NSString stringWithFormat:@"%d",missionItem.itemID]];
            [missionItemInPlayDao save:missionItemInPlay];
            
            //[APPDEL playSystemSound:@"s_quiz_fail"  fileType:@"wav"]; 
            [APPDEL playSystemSound:@"quiz_wronganswer"  fileType:@"mp3"]; 
            alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"quiz_6", nil)
                                                   message:NSLocalizedString(@"quiz_7", nil) 
                                                  delegate:self 
                                         cancelButtonTitle:NSLocalizedString(@"quiz_10", nil) 
                                         otherButtonTitles:NSLocalizedString(@"quiz_8", nil) ,nil];
            
            [alertView setTag:ALERT_FAIL];
        }
        //	[alertView setDelegate:self];
        [alertView show];
        [alertView release];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  
{ 
	if(alertView.tag == ALERT_SUCCESS) {
        [SVProgressHUD dismiss];
        if([missionItem.itemType isEqualToString:I_QUIZ]){
            [self dismissWithClickedButtonIndex:0 animated:YES];		
        }else{
            [self dismissWithClickedButtonIndex:1 animated:YES];
        }
	}else if(alertView.tag == ALERT_FAIL) {
		if(buttonIndex == 0){
            [SVProgressHUD dismiss];
            [self dismissWithClickedButtonIndex:2 animated:YES];
        }else{
            [self failQuiz];
        }
	}else if(alertView.tag == ALERT_SOLUTION || alertView.tag == ALERT_SOLUTION_ITEM) {
        [answerField resignFirstResponder];
        if(buttonIndex == 1){
            NSString *answer;
            if ([missionItem.itemType isEqualToString:I_END]) 
                answer = caller.caller.missionAnswer;
            else {
                answer = quizItem.answer;
            }
            solutionButton.hidden = TRUE;
            answerField.text = answer;
            ItemRnPInPlayDao *itemRnPInPlayDao = [[[ItemRnPInPlayDao alloc] init] autorelease];
            
            int  cnt = [[caller.caller.dicRnPTaken valueForKey:I_SOLUTION] intValue];
            if (cnt > 0) {
                ItemRnPInPlay *itemRnPInPlay = [itemRnPInPlayDao selectWithPK:missionItem.missionID 
                                                                     playerID:[APPDEL gUserID] itemType:I_SOLUTION];
                itemRnPInPlay.ableCnt--; 
                [itemRnPInPlayDao save:itemRnPInPlay];
            }
            caller.caller.dicRnPTaken = [itemRnPInPlayDao selectDicAt:missionItem.missionID 
                                                             playerID:[APPDEL gUserID]];
            
            if(alertView.tag == ALERT_SOLUTION_ITEM){
                int count = [APPDEL solutionCount] - 1;
                [APPDEL setSolutionCount:count];
            }
        }
    }
    
}


-(void)failQuiz
{	
	answerField.text = @"";
    
    if ([missionItem.itemType isEqualToString:I_END]) {
        quizSeq = 0;
        
        
        questionView.text =  [NSString stringWithFormat:NSLocalizedString(@"quiz_9", nil),caller.caller.missionQuiz];
        if(failCnt > 0) {
            
            if ([caller.caller.missionAnswer length] < 2) {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_0", nil),
                                  [caller.caller.missionAnswer length]];
            }
            else {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_1", nil),
                                  [caller.caller.missionAnswer length],
                                  [caller.caller.missionAnswer substringToIndex:1]];
            }
        }
        
    }else {
        quizSeq = arc4random() % [missionItem.itemQuizzes count];
        quizItem = [missionItem.itemQuizzes objectAtIndex:quizSeq];
        
        questionView.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_9", nil), quizItem.quiz];
        
        if(failCnt > 0) {
            
            if ([quizItem.answer length] < 2) {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_0", nil),
                                  [quizItem.answer length]];
            }
            else {
                hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"quiz_1", nil),
                                  [quizItem.answer length],
                                  [quizItem.answer substringToIndex:1]];
            }
        }
        NSLog(@"quizSeq:%d,[missionItem.itemQuizzes count]:%d",quizSeq,[missionItem.itemQuizzes count]);
    }
    
    
}



- (void) startPayment:(NSString*)productID{
    
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productID]; 
    if(payment !=nil){
        onBuy = true;
        [answerField setEnabled:false];
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
    int count = 10+ [APPDEL solutionCount];
    [APPDEL setSolutionCount:count];
    
    if ([[caller.caller.dicRnPTaken valueForKey:I_SOLUTION] intValue] > 0) {
        [solutionButton setTitle:NSLocalizedString(@"quiz_button_0", nil) forState:UIControlStateNormal];
    }else if([APPDEL solutionCount]){
        [solutionButton setTitle:NSLocalizedString(@"quiz_button_1", nil) forState:UIControlStateNormal];
    }else{
        [solutionButton setTitle:NSLocalizedString(@"quiz_button_2", nil) forState:UIControlStateNormal];
    }
}

- (void) payAlert{
    if(onBuy){
        onBuy = false;
        [answerField setEnabled:true];
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
        [answerField setEnabled:true];
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


- (void)drawRect:(CGRect)rect {
    [backgroundImage drawInRect:CGRectMake(0, 0, 280, 230)];
}

- (void) layoutSubviews {
    for (UIView *subview in self.subviews){
        if ([subview isMemberOfClass:[UIImageView class]] && subview != ArIconView) {
            subview.hidden = true; 
        }
    }
}

- (void) show {
    [super show];
    self.bounds = CGRectMake(0, 0, 280, 230);
}


- (void)dealloc {
    self.caller =nil;
    self.backgroundImage = nil;
    [super dealloc];
}



@end
