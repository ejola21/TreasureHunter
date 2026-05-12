//
//  ImageManager.m
//  TreasureHunter
//
//  Created by  on 12. 6. 21..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "ImageManager.h"

@implementation ImageManager


+ (UIImage*) ImageMerge:(UIImage*)image
{
    UIImage *secondImage = [UIImage imageNamed:@"frame160"];
	UIGraphicsBeginImageContext(image.size);
	[image drawAtPoint:CGPointMake(0,0)];
	[secondImage drawAtPoint:CGPointMake(0,0)];
    
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
    
	return [self maskImage:newImage];
}

+ (UIImage*) ImageMergeTitle:(UIImage*)image Kind:(int)kind
{
    UIImage *secondImage;
    
    if(kind == 0){
        secondImage = [self imageResizeTitleImage:[UIImage imageNamed:@"icon_1.png"]];
    }else if(kind == 1){
        secondImage = [self imageResizeTitleImage:[UIImage imageNamed:@"icon_r.png"]];
    }else{
        secondImage = [self imageResizeTitleImage:[UIImage imageNamed:@"icon_1r.png"]];
    }
	UIGraphicsBeginImageContext(image.size);
	[image drawAtPoint:CGPointMake(0,0)];
	[secondImage drawAtPoint:CGPointMake(0,0)];
    
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
    
	return [self maskImage:newImage];
}

+ (UIImage*)imageResizeTitleImage:(UIImage*)image
{   
    CGSize newSize = CGSizeMake(50.0, 50.0);
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}



+ (UIImage*)imageResizeImage:(UIImage*)image
{   
    CGSize newSize = CGSizeMake(160.0, 160.0);
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage*)loadBadgeImg:(NSString *)ImgName{
    UIImage *image;
    
    //load img from dir
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imgFilePath = [NSString stringWithFormat:@"%@/%@.png",docDir,ImgName];
    image = [UIImage imageWithContentsOfFile:imgFilePath];
    
    
    
    if(image != nil){
        return image;
    }
    
    NSString *URL = [NSString stringWithFormat:@"http://nexapp.co.kr/playspot/badge/%@.png",ImgName];
    //load img from URL
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:URL]]];
    if(image == nil){
        //load fail
        image = [UIImage imageNamed:@"empty02.png"];
        return image;
    }
    
    //save img from dir
    NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(image)];
    [data1 writeToFile:imgFilePath atomically:YES];
    
    return image;
}

+ (UIImage*)loadInfoBadgeImg:(NSString *)ImgName{
    UIImage *image;
    
    //load img from dir
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imgFilePath = [NSString stringWithFormat:@"%@/%@.png",docDir,ImgName];
    image = [UIImage imageWithContentsOfFile:imgFilePath];
    
    
    
    if(image != nil){
        return image;
    }else{
        return nil;
    }
}

+ (void) uploadImgWithID:(NSString *)imageId Image:(UIImage*) image{
    
    NSData *imageData = UIImagePNGRepresentation(image);
    
    // setting up the URL to post to
    NSString *urlString = @"http://nexapp.co.kr/playspot/image_save.php";
    
    // setting up the request object now
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    /*
     add some header info now
     we always need a boundary when we post a file
     also we need to set the content type
     
     You might want to generate a random boundary.. this is just the same 
     as my output from wireshark on a valid html post
     */
    NSString *boundary = [NSString stringWithString:@"treasurehunter"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    /*
     now lets create the body of the post
     */
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]]; 
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n",imageId] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    // now lets make the connection to the web
    [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
}

+ (void) saveImgWithID:(NSString *)imageId Image:(UIImage*) image{
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imgFilePath = [NSString stringWithFormat:@"%@/%@.png",docDir,imageId];
    NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(image)];
    [data1 writeToFile:imgFilePath atomically:YES];
}

+ (UIImage*) maskImage:(UIImage *)image {
    
    UIImage *maskImage = [UIImage imageNamed:@"mask1.png"];
    
    CGImageRef maskRef = maskImage.CGImage; 
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    CGImageRelease(mask);
    UIImage *maskedImg = [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);
    return maskedImg;
    
    
}

@end
