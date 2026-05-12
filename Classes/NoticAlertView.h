//
//  NoticAlertView.h
//  TreasureHunter
//
//  Created by  on 12. 7. 7..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NoticAlertView : UIAlertView{
    UIImage *backgroundImage;
    
    UIButton *homeButton;
    UIButton *okButton;
    
    UILabel *titleLabel;
    UILabel *messageLabel; 
    UIImageView *ArIconView;
}



@property(readwrite, retain) UIImage *backgroundImage;

- (id) initWithTitle:(NSString *)getTitle
             message:(NSString *)getMessage
              cancel:(NSString*)cancelString
                  ok:(NSString *)okString
            itemType:(NSString *)type;



@end
