//
//  MRScrollView.m
//  BProject
//
//  Created by Riky.G Kim on 10. 6. 3..
//  Copyright 2010 마이리키닷넷. All rights reserved.
//

#import "MRScrollView.h"

@implementation MRScrollView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
        UIImage* imageBG = [UIImage imageNamed:@"gameinfo.png"];
        imageView = [[UIImageView alloc] initWithImage:imageBG];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [imageView setFrame:CGRectMake(0,0,imageBG.size.width,imageBG.size.height)];
        [self addSubview:imageView];
        [imageView release];
        
        self.delegate = self;
        self.maximumZoomScale = 1.0f;
        self.minimumZoomScale = 0.4f;
        [self setContentSize:CGSizeMake(imageBG.size.width,imageBG.size.height)];
        
        [self setZoomScale:self.minimumZoomScale];
    }
    return self;
}



@end
