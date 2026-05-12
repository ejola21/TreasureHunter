//
//  StartGameAlert.m
//  TreasureHunter
//
//  Created by  on 12. 7. 16..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "StartGameAlert.h"

@implementation StartGameAlert
@synthesize backgroundImage;
@synthesize isVirtural;

- (id) initWithKind:(int)kind{
    self  = [super initWithTitle:@"" message:@"\n\n\n\n\n\n\n\n" 
                        delegate:nil 
               cancelButtonTitle:nil 
               otherButtonTitles:nil, nil]; 
    self.backgroundImage = [UIImage imageNamed:@"popup3.png"];
    
    UIButton *imgViewLogo = [[[UIButton alloc] init] autorelease];
    [imgViewLogo setBackgroundImage:[UIImage imageNamed:@"loginbg_icon.png"] forState:UIControlStateNormal];
    [imgViewLogo setFrame:CGRectMake(78, 5, 191, 46)];
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 59, 258, 100)];
    titleLabel.textColor = RGB(17, 52, 67);
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:15];
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    [titleLabel setTextAlignment:UITextAlignmentCenter];
    [titleLabel setText:NSLocalizedString(@"detail_5", nil)];
    
    segControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                            NSLocalizedString(@"detail_9", nil),
                                                            NSLocalizedString(@"detail_10", nil), nil]];
    [segControl setFrame:CGRectMake(45, 170, 191, 30)];
    
    [segControl setTintColor:[APPDEL backColor]];
    [segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [segControl addTarget:self action:@selector(segmentedChange:) forControlEvents:UIControlEventValueChanged];
    [segControl setSelectedSegmentIndex:0];
    self.isVirtural = true;
    
    btnBack = [[UIButton alloc] init];
    [btnBack addTarget:self action:@selector(backSelect:) forControlEvents:UIControlEventTouchUpInside];
    [btnBack setBackgroundImage:[UIImage imageNamed:@"loginbg_back.png"] forState:UIControlStateNormal];
    [btnBack setFrame:CGRectMake(11, 8, 56, 40)];
    
    btnLeft = [[UIButton alloc] init];
    [btnLeft addTarget:self action:@selector(leftSelect:) forControlEvents:UIControlEventTouchUpInside];
    [btnLeft setBackgroundImage:[UIImage imageNamed:@"loginbg_botton.png"] forState:UIControlStateNormal];
    [btnLeft setTitle:NSLocalizedString(@"detail_7", nil) forState:UIControlStateNormal];
    [btnLeft setFrame:CGRectMake(11, 205, 120, 33)];
    
    
    btnRight = [[UIButton alloc] init];
    [btnRight addTarget:self action:@selector(rightSelect:) forControlEvents:UIControlEventTouchUpInside];
    [btnRight setBackgroundImage:[UIImage imageNamed:@"loginbg_botton2.png"] forState:UIControlStateNormal];
    [btnRight setTitle:NSLocalizedString(@"detail_start", nil) forState:UIControlStateNormal];
    [btnRight setFrame:CGRectMake(72, 205, 136, 39)];
    
    if(kind == 1){
        [btnRight setFrame:CGRectMake(149, 205, 120, 33)];
        [btnRight setTitle:NSLocalizedString(@"detail_8", nil) forState:UIControlStateNormal];
        [self addSubview:btnLeft];
    }
    
    
    
    [self addSubview:imgViewLogo];
    [self addSubview:titleLabel];
    [self addSubview:segControl];
    [self addSubview:btnBack];
    [self addSubview:btnRight];
    return self;
}

- (void)backSelect:(id)sender
{
    
    [self dismissWithClickedButtonIndex:99 animated:YES];
}

- (void)leftSelect:(id)sender
{
    
    [self dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)rightSelect:(id)sender
{
    
    [self dismissWithClickedButtonIndex:1 animated:YES];
}

- (void)segmentedChange:(id)sender {
    if([sender selectedSegmentIndex] == 0){
        self.isVirtural = true;
    }else {
        self.isVirtural = false;
    }
}



- (void)drawRect:(CGRect)rect {
    [backgroundImage drawInRect:CGRectMake(0, 0, 280, 260)];
}

- (void) layoutSubviews {
    for (UIView *subview in self.subviews){
        if ([subview isMemberOfClass:[UIImageView class]]) {
            subview.hidden = true;
        }
    }
}

- (void) show {
    [super show];
    self.bounds = CGRectMake(0, 0, 280, 260);
}


- (void)dealloc {
    [btnBack release]; btnBack =nil;
    [btnRight release]; btnRight =nil;
    [btnLeft release]; btnLeft = nil;
    [titleLabel release]; titleLabel =nil;
    [segControl release]; segControl =nil;

    [super dealloc];
}

@end
