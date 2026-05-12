//
//  GamePlayAlert.m
//  TreasureHunter
//
//  Created by  on 12. 6. 13..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "GamePlayAlert.h"
#import "ARViewController.h"

@implementation GamePlayAlert
@synthesize accelerometerManager;

@synthesize topImg,basicImg,img0,img1;

- (id) initWithItem:(MissionItem *)getMissionItem
           GameType:(int)getGameType
          GameLevel:(int)getGameLevel{
    
    isFirst =true;
    
	missionItem = getMissionItem;
    level = getGameLevel;
    
    timeCount = 0;
    self.accelerometerManager = [UIAccelerometer sharedAccelerometer];
    self.accelerometerManager.updateInterval = 0.25;
    self.accelerometerManager.delegate = self;
    
    type = 0;
    if(arc4random()%2 == 0){
        type = 1;
    }
    self = [super initWithTitle:@"" message:@"\n\n\n\n\n\n\n\n\n\n\n\n" 
                       delegate:nil 
              cancelButtonTitle:nil 
              otherButtonTitles:nil, nil];    
    
    self.basicImg = [UIImage imageNamed:@"logo_noshadow_black.png"];
    self.topImg = [UIImage imageNamed:@"logo_noshadow.png"];
    
    progressView = [[UIImageView alloc] initWithImage:basicImg];
    [progressView setFrame:CGRectMake(0, 0, 300, 300)];
    progressTopView = [[UIImageView alloc] init];
    
    [self addSubview:progressView];
    [self addSubview:progressTopView];
    
    if(type == 0){
        self.img0 = [UIImage imageNamed:@"game_touch.png"];
        self.img1 = [UIImage imageNamed:@"game_touch1.png"];
    }else{
        self.img0 = [UIImage imageNamed:@"game_shake.png"];
        self.img1 = [UIImage imageNamed:@"game_shake1.png"];
    }
    
    
    
    modeView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, 300, 300)];
    [modeView setImage:img0];
    [self addSubview:modeView];
    
    homeButton = [[UIButton alloc] init];
    [homeButton addTarget:self action:@selector(homeSelect:) forControlEvents:UIControlEventTouchUpInside];
    [homeButton setBackgroundColor:[UIColor clearColor]];
    
    [homeButton setFrame:CGRectMake(0, 0, 300, 400)];
    
    if(type == 0){
        [self addSubview:homeButton];
    }
    count = 0;
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.1  target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    
    return self;
}


- (UIImage *)croppedImage:(UIImage*)image Cut:(float)cutCount{
    if(cutCount == 0){
        return image;
    }
    float partWidth = image.size.width*cutCount* image.scale;
    CGRect newFrame = CGRectMake(0, 0, partWidth , image.size.height * image.scale);
    CGImageRef resultImage = CGImageCreateWithImageInRect([image CGImage], newFrame);
    UIImage *result = [UIImage imageWithCGImage:resultImage scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(resultImage);
    return result;
}

- (UIImage *)croppedVerticalImage:(UIImage*)image Cut:(float)cutCount{
    if(cutCount == 0){
        return image;
    }
    float partHeight = image.size.height*cutCount*image.scale;
    CGRect newFrame = CGRectMake(0, image.size.height*(1-cutCount)*image.scale, image.size.width * image.scale, partHeight);
    
    CGImageRef resultImage = CGImageCreateWithImageInRect([image CGImage], newFrame);
    
    UIImage *result = [UIImage imageWithCGImage:resultImage scale:image.scale orientation:image.imageOrientation];
    
    CGImageRelease(resultImage);
    return result;
}

#define kFilteringFactor 0.05
UIAccelerationValue rollingX, rollingZ;

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    if(fabsf(acceleration.x) > 1.4 || fabsf(acceleration.y) > 1.4 || fabsf(acceleration.z) > 1.4)
    {
        if(type == 1){
            if(level == 1){
                timeCount += 7;
            }else if(level == 2){
                timeCount += 6;
            }else if(level == 3){
                timeCount += 5;
            }else{
                timeCount += 8;
            }
        }
    }
}

- (void)homeSelect:(id)sender
{
    
    if(type == 0){
        if(level == 1){
            timeCount += 6;
        }else if(level == 2){
            timeCount += 5;
        }else if(level == 3){
            timeCount += 4;
        }else{
            timeCount += 7;
        }
    }
}

- (void)updateTime{
    if(timeCount >0){
        timeCount --;  
    }
    
    if(timeCount < 20){
        [modeView setAlpha: (float)(20 - timeCount)/20];
    }else{
        [modeView setAlpha:0]; 
    }

    count++;
    if(count %3 == 0){
        
        if(count %6 == 0){
            [modeView setImage:img0];
        }else{
            [modeView setImage:img1];
        }
    }
    [progressTopView setImage:[self croppedVerticalImage:topImg Cut:(float)timeCount/100]];
    [progressTopView setFrame:CGRectMake(0, 3*(100-timeCount), 300 , 3*timeCount)];
    
    if(timeCount >= 100 && isFirst){
        isFirst = false;
        if(timer != nil ){
            [timer invalidate]; 
            timer =nil;
        }
        [APPDEL playSystemSound:@"game_finish"  fileType:@"mp3"];
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"success", nil)
                                                            message:NSLocalizedString(@"success_message", nil)
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        
        [alertView show];
        [alertView release];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  
{ 
    [self dismissWithClickedButtonIndex:3 animated:YES];
}


- (void)drawRect:(CGRect)rect {
}

- (void) layoutSubviews {
    for (UIView *subview in self.subviews){
        if ([subview isMemberOfClass:[UIImageView class]] && subview != progressView && subview != progressTopView && subview != modeView) {
            subview.hidden = YES;
        }
    }
}

- (void) show {
    [super show];
}
- (void)dealloc {
    self.accelerometerManager.delegate = nil;
    [accelerometerManager release];
    [progressView release];
    [progressTopView release];
    [modeView release];
    [homeButton release];
    self.topImg = nil;
    self.basicImg = nil;
    self.img0 = nil;
    self.img1 = nil;
    
    [super dealloc];
}


@end
