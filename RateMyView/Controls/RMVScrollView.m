//
//  RMVScrollView.m
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVScrollView.h"
#define kGapBetweenView 10.0f
@implementation RMVScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
}

-(void)layoutView
{
    __block CGFloat height = 0;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    //hide the bars so not included
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView* subview = (UIView*)obj;
        subview.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        
        if([obj isKindOfClass:[UITextView class]] && !subview.hidden)
        {
            UITextView* txtSubview = (UITextView*)obj;
            CGSize size = [txtSubview.text sizeWithFont:txtSubview.font constrainedToSize:CGSizeMake(txtSubview.frame.size.width, CGFLOAT_MAX)];
            CGRect subviewFrame = txtSubview.frame;
            subviewFrame.size.height = size.height + 30;
            txtSubview.frame = subviewFrame;
            subview = txtSubview;
        }
        
        if(!subview.hidden){
            CGRect frame = subview.frame;
            frame.origin.y = height;
            height += frame.size.height + kGapBetweenView;
            subview.frame = frame;
        }
        
        
    }];
    self.contentSize = CGSizeMake(self.frame.size.width, height + (kIsiOS7 ? 2*kGapBetweenView : 4*kGapBetweenView));
    self.showsHorizontalScrollIndicator = YES;
    self.showsVerticalScrollIndicator = YES;

    if ([self.layoutDelegate respondsToSelector:@selector(didLayoutView:)]) {
        [self.layoutDelegate didLayoutView:self];
    }
    
}

-(void)cleanup
{
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView* subview = (UIView*)obj;
        [subview removeFromSuperview];
    }];
    
    self.showsHorizontalScrollIndicator = YES;
    self.showsVerticalScrollIndicator = YES;
    //ios7 kix
    [self setContentOffset:CGPointMake(self.contentOffset.x, -self.contentInset.top) animated:YES];}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
