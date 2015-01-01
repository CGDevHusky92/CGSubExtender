//
//  UITextField+AUTOCOMP.h
//  REPO
//
//  Created by Charles Gorectke on 7/17/14.
//  Copyright (c) 2014 Jackson. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UITextFieldAutoDelegate <UITextFieldDelegate>

@optional
- (void)textField:(UITextField *)textField autoCompleteMatchFoundForTextField:(NSString *)text;
- (void)textField:(UITextField *)textField dismissingAutoTextFieldWithFinalText:(NSString *)text;

- (BOOL)textFieldShouldReturn:(UITextField *)textField;

@end

@protocol UITextFieldAutoDataSource <NSObject>

@optional
- (NSString *)textField:(UITextField *)textField autoCompleteDictionaryDataForIndex:(NSUInteger)index;

@end

@protocol CGAutoCompletePopoverDelegate <NSObject>

- (NSString *)currentAutoFieldText;
- (NSArray *)initialAutoStrings;
- (void)currentSelectionInPicker:(NSString *)selected;
- (void)returnSelectedString:(NSString *)selected;

@end

@interface CGAutoCompleteViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>;

@property (weak, nonatomic) id<CGAutoCompletePopoverDelegate> delegate;

- (instancetype)initWithSelectables:(NSArray *)selectables;
- (void)completeAutoSelection:(NSString *)selectedText;

@end

@interface UITextField (AUTOCOMP) <CGAutoCompletePopoverDelegate>

@property (weak, nonatomic) id<UITextFieldAutoDelegate> autoDelegate;

@property (strong, nonatomic) CGAutoCompleteViewController *autoController;
@property (strong, nonatomic) UIPopoverController * autoPopController;
@property (strong, nonatomic) NSArray * autoCompleteDictionary;

- (void)setAutoDelegate:(id<UITextFieldAutoDelegate>)delegate;
- (id<UITextFieldAutoDelegate>)autoDelegate;

- (void)startAutoCompleteWithDictionary:(NSArray *)autoCompleteDictionary withPickerView:(BOOL)pickerEnabled;
- (void)startAutoCompleteWithFile:(NSString *)fileName withPickerView:(BOOL)pickerEnabled;

@end



