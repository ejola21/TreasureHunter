/*
 Disclaimer: IMPORTANT:  This About Objects software is supplied to you by
 About Objects, Inc. ("AOI") in consideration of your agreement to the 
 following terms, and your use, installation, modification or redistribution
 of this AOI software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this AOI software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, AOI grants you a personal, non-exclusive
 license, under AOI's copyrights in this original AOI software (the
 "AOI Software"), to use, reproduce, modify and redistribute the AOI
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the AOI Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the AOI Software.
 Neither the name, trademarks, service marks or logos of About Objects, Inc.
 may be used to endorse or promote products derived from the AOI Software
 without specific prior written permission from AOI.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by AOI herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the AOI Software may be incorporated.
 
 The AOI Software is provided by AOI on an "AS IS" basis.  AOI
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE AOI SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL AOI BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE AOI SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF AOI HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) About Objects, Inc. 2009. All rights reserved.
 */
#import "EditableDetailCell.h"

@implementation EditableDetailCell

@synthesize textField = _textField, label = _label, textView = _textView;

#pragma mark -

- (void)dealloc
{
	//  We're performing a delayed release here to give delegate notification 
	//  messages time to propagate. Specifically, MyDetailController implements
	//  the -textFieldDidEndEditing: delegate method, which is sent by an
	//  instance of NSNotificationCenter during the next event cycle. Without
	//  the delay, the textField would get released before the message is sent.
	//  But the textField is an argument to that method, so the method would 
	//  be passed an invalid reference, which would be likely to crash the app.
	//
	
	[_textField performSelector:@selector(release)
									 withObject:nil
									 afterDelay:1.0];
	[_label	performSelector:@selector(release)
							 withObject:nil
							 afterDelay:1.0];
	[_textView	performSelector:@selector(release)
									withObject:nil
									afterDelay:1.0];
	
	
	[super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)identifier
{
	
	self = [super initWithStyle:style reuseIdentifier:identifier];
	
	if (self == nil)
	{ 
		return nil;
	}
	
	CGRect bounds = [[self contentView] bounds];    
	
	CGRect labelRect = CGRectMake(bounds.origin.x+10, bounds.origin.y-5,70, bounds.size.height-10);
	CGRect textRect = CGRectMake(bounds.origin.x-50, bounds.origin.y-10,bounds.size.width-55, bounds.size.height-20);
	
	_label =[[UILabel alloc] initWithFrame:CGRectZero];
	_textField = [[UITextField alloc] initWithFrame:CGRectZero];
	_textView =[[UITextView alloc] initWithFrame:CGRectZero];
	
	
	if (identifier == nil) 
	{
		//CGRect bounds = [[self contentView] bounds];
		
		_label.textAlignment = UITextAlignmentLeft;
		_label.font = [UIFont systemFontOfSize:14];
		//_label.textColor =[UIColor viewFlipsideBackgroundColor];
		_label.textColor = [UIColor darkGrayColor];
		
		[[self contentView] addSubview:_label];
		[_label setFrame:CGRectMake(5.0f,5.0f,labelRect.size.width,labelRect.size.height)];
		
		//  Set the keyboard's return key label to 'Next'.
		[_textField setReturnKeyType:UIReturnKeyDone];
		
		//  Make the clear button appear automatically.
		[_textField setClearButtonMode:UITextFieldViewModeWhileEditing];
		[_textField setBackgroundColor:[UIColor whiteColor]];
		_textField.font = [UIFont systemFontOfSize:17];
		_textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_textField setOpaque:YES];
		
		[[self contentView] addSubview:_textField];
		[_textField setFrame:CGRectMake(70,12,textRect.size.width,textRect.size.height)];
		
		[self setTextField:_textField];
		
	}
	else 
	{
		_label.tag = CELL_LABEL;
		_label.font = [UIFont systemFontOfSize:14];
		_label.textColor = [UIColor darkGrayColor];
		
		[_textView setEditable:YES];
		[_textView setScrollEnabled:NO];
		
		[_textView setFont:[UIFont systemFontOfSize:15]];
		[_textView setReturnKeyType:UIReturnKeyDone];
		
		_textView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth );
		_textView.tag = CELL_TEXTVIEW;
		_textView.contentInset = UIEdgeInsetsZero;
		
		//[self.contentView setFrame:CGRectMake(0, 0, self.contentView.bounds.size.width - 10.0f,80.0)];					
		[self.contentView addSubview:_label];		
		[_label setFrame:CGRectMake(15.0f, 5.0f, 240.0f, 25.0f)];
		[self.contentView addSubview:_textView]; 

		//도대체 height가외  
		[_textView setFrame:CGRectMake(5.0f, 30.0f, self.contentView.bounds.size.width - 10.0,10.0)];
		
		
		
		//[_textView setFrame:CGRectMake(5.0f, 28.0f,bounds.size.width - 10.0f, bounds.size.height - 28.0f)];
		//[self.contentView setFrame:CGRectMake(0, 0, bounds.size.width - 10.0f, bounds.size.height)]; 
		
		
		//(0, 0,bounds.size.width-10,0)];
		
		//[self setTextView:textView]; 
		//[textView setFrame:CGRectMake(5,5,bounds.size.width-100,bounds.size.height*3-20)];
		//[textView sizeToFit];	
	}
	
	return self;
}

//  Disable highlighting of currently selected cell.
//
- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated 
{
	[super setSelected:selected animated:NO];
	
	[self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

/*
 
 
 //텍스트값 체크
 - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
 { 
 //return NO하면 입력이 취소됨
 //return YES하면 입력이 허락됨
 //textField 이용해서 어느 텍스트필드인지 구분 가능
 
 //최대길이
 int maxLength = 256;
 NSString *candidateString;
 NSNumber *candidateNumber;
 
 //입력 들어온 값을 담아둔다
 candidateString = [textField.text stringByReplacingCharactersInRange:range withString:string];
 
 if(textField == IDField) {
 maxLength = 8;
 } else if(textField == AgeField) {
 //숫자여부 점검
 
 //length가 0보다 클 경우만 체크
 //0인 경우는 백스페이스의 경우이므로 체크하지 않아야 한다
 if ([string length] > 0) {
 //numberFormatter는 자주 사용할 예정이므로 아래 코드를 이용해서 생성해둬야함
 //numberFormatter = [[NSNumberFormatter alloc] init];
 //[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
 
 //numberFormatter 를 이용해서 NSNumber로 변환
 candidateNumber = [numberFormatter numberFromString:candidateString];
 
 //nil이면 숫자가 아니므로 NO 리턴해서 입력취소
 if(candidateNumber == nil) {
 return NO;
 }
 
 //원 래 문자열과 숫자로 변환한 후의 값이 문자열 비교시 다르면
 //숫자가 아닌 부분이 섞여있다는 의미임
 if ([[candidateNumber stringValue] compare:candidateString] !=  NSOrderedSame) {
 return NO;
 }
 
 maxLength = 2;
 }
 }
 
 //길이 초과 점검
 if ([candidateString length] > maxLength) {
 return NO;
 }
 
 return YES;
 }
 */
@end
