//
//  TextAlertView.h
//  LXylophone
//
//  Created by Chunkwon on 11. 9. 19..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLStarRatingControl.h"

@interface TextAlertView :  UIAlertView <UITextFieldDelegate>{
    
    UITextField	*mTextField;
    DLStarRatingControl *customNumberOfStars;
    
}

@property (nonatomic, retain) UITextField *mTextField;
@property (readonly) NSString *enteredText;
@property (readonly) float starRate;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle;

@end
