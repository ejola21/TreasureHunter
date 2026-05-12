//
//  ImageManager.h
//  TreasureHunter
//
//  Created by  on 12. 6. 21..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageManager : NSObject

+ (UIImage*) ImageMerge:(UIImage*)image;
+ (UIImage*)imageResizeImage:(UIImage*)image;
+ (UIImage*)loadBadgeImg:(NSString *)ImgName;
+ (UIImage*)loadInfoBadgeImg:(NSString *)ImgName;
+ (void) uploadImgWithID:(NSString *)imageId Image:(UIImage*) image;

+ (void) saveImgWithID:(NSString *)imageId Image:(UIImage*) image;
+ (UIImage*) maskImage:(UIImage *)image ;
+ (UIImage*) ImageMergeTitle:(UIImage*)image Kind:(int)kind;
@end
