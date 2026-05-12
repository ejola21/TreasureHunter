//
//  MyClass.h
//  AR
//
//  Created by wang  chao on 11-12-23.
//  Copyright 2011年 bupt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MultiPickerDelegate;

@interface MultiPickerView : UIPickerView<UIPickerViewDelegate,UIPickerViewDataSource>{
    NSMutableArray* _showData;
    NSDictionary* _data;
    NSInteger _level;
    id<MultiPickerDelegate> _mdelegate;
}

@property (nonatomic,retain) NSMutableArray* showData;
@property (nonatomic,assign) id mdelegate;
@property (nonatomic,retain) NSDictionary* data;
@property (nonatomic,readonly) NSArray* selections;

- (BOOL)selectKey:(NSString*)key;

@end

@protocol MultiPickerDelegate 

- (void)selectionChanged:(NSArray*)selections;

@end
