//
//  MyClass.m
//  AR
//
//  Created by wang  chao on 11-12-23.
//  Copyright 2011年 bupt. All rights reserved.
//

#import "MultiPickerView.h"

@interface  MultiPickerView (Private)

- (void)_setSelection:(NSArray*)selections;
- (NSArray*)_postionForKey:(NSString*)key;

@end

@implementation MultiPickerView (Private)

- (void)_setSelection:(NSArray *)selections{
    self.showData = [NSMutableArray arrayWithCapacity:_level];
    NSArray* dataArray = [_data objectForKey:@"data"];
    NSArray* tmp = dataArray;
    if (!tmp) {
        tmp = [NSArray array];
    }
    
    if (!selections) {
        selections = [NSArray array];
    }
    
    if ([selections count]<_level) {
        NSMutableArray* tmpSelections = [NSMutableArray arrayWithArray:selections];
        for (NSInteger i=0; i<(_level-[selections count]); i++) {
            [tmpSelections addObject:[NSNumber numberWithInt:0]];
        }
        selections = tmpSelections;
    }
    
    for (NSInteger i=0; i<_level; i++) {
        [self.showData addObject:tmp];
        if ([tmp count] > 0) {
            NSInteger index = [[selections objectAtIndex:i] intValue];
            if (index >= [tmp count]) {
                index = [tmp count] - 1;
            }
            NSArray* tmp2 = [[tmp objectAtIndex:index] objectForKey:@"children"];
            if (!tmp2) {
                tmp = [NSArray arrayWithObject:[tmp objectAtIndex:index]];
            }else{
                tmp = tmp2;
            }
        }
    }
    
    
    [self reloadAllComponents];
    
    for (NSInteger i=0;i<[selections count];i++) {
        NSNumber* selection = [selections objectAtIndex:i];
        [self selectRow:[selection intValue] inComponent:i animated:NO];
    }
    
}

- (NSArray*)_postionForKey:(NSString *)key{
    BOOL foundFlag = NO;
    NSMutableArray* postion = [NSMutableArray array];
    NSArray* dataArray = [_data objectForKey:@"data"];
    
    if (!dataArray) {
        return nil;
    }
    
    NSArray* tmpArray = dataArray;
    [postion addObject:[NSNumber numberWithInt:0]];
    NSMutableArray* searchPath = [NSMutableArray array];
    [searchPath addObject:[NSDictionary dictionaryWithObject:dataArray forKey:@"children"]];
    
    while (YES) {
        
        if ([tmpArray count] <=0) {
            foundFlag = NO;
            break;
        }
        
        NSInteger topPos = [[postion lastObject] intValue];
        
        if (topPos >= [tmpArray count]) {
            [postion removeLastObject];
            topPos = [[postion lastObject] intValue] + 1;
            [postion replaceObjectAtIndex:[postion count]-1 withObject:[NSNumber numberWithInt:topPos]];
            [searchPath removeLastObject];
            tmpArray = [[searchPath lastObject] objectForKey:@"children"];
            continue;
        }
        
        
        NSDictionary* dict = [tmpArray objectAtIndex:topPos];
        NSString* tmpKey = [dict objectForKey:@"key"];
        if ([key isEqualToString:tmpKey]) {
            foundFlag = YES;
            break;
        }
        
        NSArray* subArray = [dict objectForKey:@"children"];
        if (!subArray || [subArray count] == 0) { 
            topPos += 1;
            [postion replaceObjectAtIndex:[postion count]-1 withObject:[NSNumber numberWithInt:topPos]];
        }else{
            [postion addObject:[NSNumber numberWithInt:0]];
            [searchPath addObject:dict];
            tmpArray = subArray;
        }
    }
    
    if (foundFlag) {
        return postion;
    }
    return nil;
}

@end


@implementation MultiPickerView

@synthesize showData = _showData;
@synthesize data = _data;
@synthesize mdelegate = _mdelegate;

#pragma mark - 

- (BOOL)selectKey:(NSString *)key{
    NSArray* position = [self _postionForKey:key];
    if (!position) {
        return NO;
    }
    [self _setSelection:position];
    return YES;
}

#pragma mark - setters&getters

- (NSArray*)selections{
    NSMutableArray* selections = [NSMutableArray arrayWithCapacity:_level];
    for (NSInteger i=0; i<_level; i++) {
        NSInteger selected = [self selectedRowInComponent:i];
        if (selected == -1) {
            return nil;
        }
        NSDictionary* dict = [[_showData objectAtIndex:i] objectAtIndex:selected];
        [selections addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               [dict objectForKey:@"key"],@"key",
                               [dict objectForKey:@"value"],@"value"
                               , nil]];
    }
    return selections;
}

- (void)setData:(NSDictionary *)data{
    [data retain];
    [_data release];
    _data = data;
    if (data == nil) {
        _level = 0;
        return;
    }
    _level = [[data objectForKey:@"level"] intValue];
    self.delegate = self;
    self.showsSelectionIndicator = YES;
    [self _setSelection:nil];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return _level;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [[_showData objectAtIndex:component] count];
}

#pragma mark - UIPickerViewDelegate
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	NSInteger ret = 0;
	
	if (component == 0)
		ret = (320 * 0.45);
	else if (component == 1)
		ret = (320 * 0.32);
	else if (component == 2)
		ret = (320 * 0.23);
    
	return ret;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSArray* data = [_showData objectAtIndex:component];
    return [[data objectAtIndex:row] objectForKey:@"value"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSMutableArray* selections = [NSMutableArray array];
    for (NSInteger i=0; i<component; i++) {
        NSNumber* selected =  [NSNumber numberWithInt:[self selectedRowInComponent:i]];
        [selections addObject:selected];
    }
    NSNumber* selected =  [NSNumber numberWithInt:row];
    [selections addObject:selected];
    [self _setSelection:selections];
    [self.mdelegate selectionChanged:self.selections];
}

#pragma mark - manage memory


- (void)dealloc{
    [_showData release];
    [_data release];
    [super dealloc];
}

@end
