//
//  TextAlertView.m
//  LXylophone
//
//  Created by Chunkwon on 11. 9. 19..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextAlertView.h"


@implementation TextAlertView

#define MAXLENGTH	100


@synthesize mTextField;
@synthesize enteredText;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okayButtonTitle
{
    
	self = [super initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:okayButtonTitle, nil];
	
    
    customNumberOfStars = [[[DLStarRatingControl alloc] initWithFrame:CGRectMake(12.0, 95.0, 260.0, 25.0) andStars:5 isFractional:true setSize0to20:20 clickEnabled:true] autorelease];
    customNumberOfStars.rating = 2.5;
    
    [self addSubview:customNumberOfStars];
    
    UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 130.0, 260.0, 25.0)]; 
    [theTextField setBackgroundColor:[UIColor whiteColor]]; 
    theTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [theTextField setPlaceholder:NSLocalizedString(@"text_alert_0", nil)];
    [self addSubview:theTextField];
    
    self.mTextField = theTextField;
    self.mTextField.delegate = self;
    
    [theTextField release];
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 10.0); 
    [self setTransform:translate];
	
	return self;
}

// TextField 글자수 제한걸기
- (BOOL)textField:
(UITextField *)textField shouldChangeCharactersInRange:
(NSRange)range replacementString:(NSString *)string 
{
	NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > MAXLENGTH) ? NO : YES;
}

- (void)show
{
	[mTextField becomeFirstResponder];
	[super show];
}
- (NSString *)enteredText
{
	return mTextField.text;
}

- (float) starRate{
    return customNumberOfStars.rating;
}

- (void)dealloc
{
	[mTextField release];
	[super dealloc];
}

@end
