//
//  UITextField+AUTOCOMP.m
//  REPO
//
//  Created by Charles Gorectke on 7/17/14.
//  Copyright (c) 2014 Jackson. All rights reserved.
//

#import "UITextField+AUTOCOMP.h"
#import "objc/runtime.h"

struct {
    unsigned int autoCompleteMatchFoundForTextField;
    unsigned int dismissingAutoTextField;
} delegateRespondsTo;

static char delKey;
static char dicKey;
static char inputKey;
static char outputKey;

static char autoControllerKey;
static char autoPopoverKey;

@implementation UITextField (AUTOCOMP)
@dynamic autoDelegate;
@dynamic autoController;
@dynamic autoPopController;

- (void)setAutoDelegate:(id<UITextFieldAutoDelegate>)delegate
{
    objc_setAssociatedObject(self, &delKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    delegateRespondsTo.autoCompleteMatchFoundForTextField = [delegate respondsToSelector:@selector(textField:autoCompleteMatchFoundForTextField:)];
    delegateRespondsTo.dismissingAutoTextField = [delegate respondsToSelector:@selector(textField:dismissingAutoTextFieldWithFinalText:)];
}

- (id<UITextFieldAutoDelegate>)autoDelegate
{
    return objc_getAssociatedObject(self, &delKey);
}

- (void)setAutoCompleteDictionary:(NSArray *)autoCompleteDictionary
{
    objc_setAssociatedObject(self, &dicKey, autoCompleteDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)autoCompleteDictionary
{
    return objc_getAssociatedObject(self, &dicKey);
}

- (void)setInputTemp:(NSString *)inputTemp
{
    objc_setAssociatedObject(self, &inputKey, inputTemp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)inputTemp
{
    return objc_getAssociatedObject(self, &inputKey);
}

- (void)setOutputTemp:(NSString *)outputTemp
{
    objc_setAssociatedObject(self, &outputKey, outputTemp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)outputTemp
{
    return objc_getAssociatedObject(self, &outputKey);
}

- (void)setAutoController:(CGAutoCompleteViewController *)autoController
{
    objc_setAssociatedObject(self, &autoControllerKey, autoController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGAutoCompleteViewController *)autoController
{
    return objc_getAssociatedObject(self, &autoControllerKey);
}

- (void)setAutoPopController:(UIPopoverController *)autoPopController
{
    objc_setAssociatedObject(self, &autoPopoverKey, autoPopController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIPopoverController *)autoPopController
{
    return objc_getAssociatedObject(self, &autoPopoverKey);
}

#pragma mark - Auto Complete Protocol

- (void)startAutoCompleteWithDictionary:(NSArray *)autoCompleteDictionary withPickerView:(BOOL)pickerEnabled
{
    self.autoCompleteDictionary = autoCompleteDictionary;
    [self addTarget:self action:@selector(autocomplete) forControlEvents:UIControlEventEditingChanged];
    
#warning assert not iPhone
    if (pickerEnabled && autoCompleteDictionary && [autoCompleteDictionary count] > 0 && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
        [self addTarget:self action:@selector(displayPopover) forControlEvents:UIControlEventEditingDidBegin];
        self.autoController = [[CGAutoCompleteViewController alloc] initWithSelectables:autoCompleteDictionary];
        self.autoController.delegate = self;
        self.autoPopController = [[UIPopoverController alloc] initWithContentViewController:self.autoController];
        self.autoPopController.popoverContentSize = self.autoController.view.frame.size;
    }
}

- (void)startAutoCompleteWithFile:(NSString *)fileName withPickerView:(BOOL)pickerEnabled
{
    NSError * error;
    NSString * filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"csv"];
    NSString * csvContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (!error) {
        NSArray * fileContents = [csvContents componentsSeparatedByString:@","];
        [self startAutoCompleteWithDictionary:fileContents withPickerView:pickerEnabled];
    } else {
        // Error occured throw exception
#warning Throw exception
    }
}

- (void)displayPopover
{
    [self.autoPopController presentPopoverFromRect:self.frame inView:self.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)autocomplete
{
    BOOL backspaced = [self.inputTemp hasPrefix:[self text]];
    self.inputTemp = [self text];
    if (!backspaced && [[self text] length] > 0) {
        self.outputTemp = [self text];
        BOOL foundMatch = NO;
        
        //Try to find a match in list of majors
        for (NSString *curMajor in self.autoCompleteDictionary) {
            NSRange range = [curMajor rangeOfString:self.inputTemp options:NSCaseInsensitiveSearch | NSAnchoredSearch];
            if (range.location != NSNotFound) {
                self.inputTemp = [curMajor substringWithRange:range]; //Since case may change
                self.outputTemp = curMajor;
                [self.autoController completeAutoSelection:curMajor];
                foundMatch = YES;
                break;
            }
        }
        
        // Set the text to output (will hold the matching major, or what was typed if no match found)
        // then select the portion of the string that was completed
        UITextPosition * start = [self selectedTextRange].start;
        [self setText:self.outputTemp];
        UITextPosition * end = [self selectedTextRange].start;
        UITextRange *selectRange = [self textRangeFromPosition:start toPosition:end];
        [self setSelectedTextRange:selectRange];
        
        // If a match was found in the majors list (and the popover is initialized), select that row in the popover
        if (foundMatch) {
            if (delegateRespondsTo.autoCompleteMatchFoundForTextField)
                [((id<UITextFieldAutoDelegate>)self.delegate) textField:self autoCompleteMatchFoundForTextField:self.text];
        }
    }
}

#pragma mark - CGAutoPicker Delegate

- (NSString *)currentAutoFieldText
{
    return self.text;
}

- (NSArray *)initialAutoStrings
{
    return self.autoCompleteDictionary;
}

- (void)currentSelectionInPicker:(NSString *)selected
{
    self.text = selected;
    self.inputTemp = selected;
}

- (void)returnSelectedString:(NSString *)selected
{
    self.text = selected;
    self.inputTemp = selected;
    if (delegateRespondsTo.dismissingAutoTextField)
        [((id<UITextFieldAutoDelegate>)self.delegate) textField:self dismissingAutoTextFieldWithFinalText:self.text];
    [self resignFirstResponder];
}

@end

@interface CGAutoCompleteViewController ()

@property (strong, nonatomic) UIPickerView * autoPicker;
@property (strong, nonatomic) NSArray * autoStrings;
@property (strong, nonatomic) NSString * selectedText;

@end

@implementation CGAutoCompleteViewController

- (instancetype)initWithSelectables:(NSArray *)selectables
{
    self = [super init];
    if (self) {
        _autoStrings = selectables;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect frame;
    CGFloat width = 0.0;
    if (_autoStrings && [_autoStrings count] > 0) {
        NSUInteger longestIndex = 0;
        for (int i = 0; i < [_autoStrings count]; i++) {
            NSString * tempStr = [_autoStrings objectAtIndex:i];
            if ([tempStr length] > [[_autoStrings objectAtIndex:longestIndex] length]) longestIndex = i;
        }
        width = [self generateWidthFromAttributesAndText:[_autoStrings objectAtIndex:longestIndex]] + (2 * 20.0);
    } else {
        width = 500.0;
    }
    
    if (width > [[[UIApplication sharedApplication] delegate] window].frame.size.width)
        width = [[[UIApplication sharedApplication] delegate] window].frame.size.width;
    frame = CGRectMake(0, 0, width, 216);
    [self.view setFrame:frame];
    
    _autoPicker = [[UIPickerView alloc] initWithFrame:frame];
    [_autoPicker setDelegate:self];
    [_autoPicker setDataSource:self];
    [self.view addSubview:_autoPicker];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _selectedText = [self.delegate currentAutoFieldText];
    _autoStrings = [self.delegate initialAutoStrings];
    if (_selectedText.length > 0)
        [self completeAutoSelection:_selectedText];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Set the selected major back in the parent
    _selectedText = [_autoStrings objectAtIndex:[_autoPicker selectedRowInComponent:0]];
    [self.delegate returnSelectedString:_selectedText];
    [super viewWillDisappear:animated];
}

#pragma mark - CGAutoPicker Delegate

- (void)completeAutoSelection:(NSString *)selectedText
{
    // Select the row for the current auto-completed major
    [_autoPicker selectRow:[_autoStrings indexOfObject:selectedText] inComponent:0 animated:NO];
    
}

#pragma mark - Picker View Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [_autoStrings count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [_autoStrings objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.delegate currentSelectionInPicker:[_autoStrings objectAtIndex:row]];
}

#pragma mark - Text Size Generation

- (CGFloat)generateWidthFromCurrentAttributesAndText
{
    return [self generateWidthFromAttributesAndText:[_autoStrings objectAtIndex:[_autoPicker selectedRowInComponent:0]]];
}

- (CGFloat)generateWidthFromAttributesAndText:(NSString *)text
{
    if (!text) return -1.0;
    NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[UIFont systemFontOfSize:23.5], NSFontAttributeName, nil];
    return ceil([text sizeWithAttributes:attributes].width);
}

#pragma mark - Memory Protocol

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
