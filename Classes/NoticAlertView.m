//
//  NoticAlertView.m
//  TreasureHunter
//
//  Created by  on 12. 7. 7..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "NoticAlertView.h"
#import <QuartzCore/QuartzCore.h>

@implementation NoticAlertView

@synthesize backgroundImage;




- (id) initWithTitle:(NSString *)getTitle
             message:(NSString *)getMessage
              cancel:(NSString*)cancelString
                  ok:(NSString *)okString
            itemType:(NSString *)type{
    
    self  = [super initWithTitle:@"" message:@"\n\n\n\n\n\n\n" 
                        delegate:nil 
               cancelButtonTitle:nil 
               otherButtonTitles:nil, nil]; 
    self.backgroundImage = [UIImage imageNamed:@"popup1.png"];
    
    
    UIButton *imgViewLogo = [[UIButton alloc] init];
    [imgViewLogo setBackgroundImage:[UIImage imageNamed:@"loginbg_icon.png"] forState:UIControlStateNormal];
    [imgViewLogo setFrame:CGRectMake(45, 5, 191, 46)];
    
    if(![self stringIsEmpty:type]){
        ArIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:type]];
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
    }
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 59, 258, 30)];
    titleLabel.textColor = RGB(17, 52, 67);
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:23];
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    [titleLabel setTextAlignment:UITextAlignmentCenter];
    [titleLabel setText:getTitle];
    
    if ([self stringIsEmpty:getMessage]) {
        [titleLabel setFrame:CGRectMake(11, 75, 258, 80)];
    }
    
    messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 97, 258, 80)];
    messageLabel.textColor = RGB(17, 52, 67);
    messageLabel.backgroundColor = [UIColor clearColor];
    [messageLabel setTextAlignment:UITextAlignmentCenter];
    messageLabel.numberOfLines = 0;
    [messageLabel setFont:[UIFont boldSystemFontOfSize:17]];
    messageLabel.lineBreakMode = UILineBreakModeWordWrap;
    [messageLabel setText:getMessage];
    
    homeButton = [[UIButton alloc] init];
    [homeButton addTarget:self action:@selector(homeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [homeButton setBackgroundImage:[UIImage imageNamed:@"loginbg_botton.png"] forState:UIControlStateNormal];
    [homeButton setTitle:cancelString forState:UIControlStateNormal];
    [homeButton setFrame:CGRectMake(72, 180, 136, 39)];
    
    if(okString != nil){
        okButton = [[UIButton alloc] init];
        [okButton addTarget:self action:@selector(okSelect:) forControlEvents:UIControlEventTouchUpInside];
        [okButton setBackgroundImage:[UIImage imageNamed:@"loginbg_botton2.png"] forState:UIControlStateNormal];
        [okButton setTitle:okString forState:UIControlStateNormal];
        [okButton setFrame:CGRectMake(149, 180, 120, 33)];
        [self addSubview:okButton];
        
        [homeButton setFrame:CGRectMake(11, 180, 120, 33)];
    }
    
    
    [self addSubview:imgViewLogo];
    [self addSubview:titleLabel];
    [self addSubview:messageLabel];
    [self addSubview:homeButton];
    [imgViewLogo release];
    
    
    return self;
    
    
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

- (void)homeSelect:(id)sender
{
    
    [self dismissWithClickedButtonIndex:4 animated:YES];
}

- (void)okSelect:(id)sender
{
    
    [self dismissWithClickedButtonIndex:5 animated:YES];
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
    [okButton release]; okButton=nil;
    [homeButton release]; homeButton =nil;
    [messageLabel release]; messageLabel= nil;
    [titleLabel release]; titleLabel =nil;
    [ArIconView release]; ArIconView = nil;
    [super dealloc];
}


@end
