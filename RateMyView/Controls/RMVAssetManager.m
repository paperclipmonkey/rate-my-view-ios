//
//  RMVAssetManager.m
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "RMVAssetManager.h"

@implementation RMVAssetManager

+(UIFont*)headingFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"HelveticaNeue" size:size];
}

+(UIFont*)italicFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:size];
}

+(UIFont*)bodyFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
}

+(UIFont*)boldFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:size];
}

+(UIButton*)blueButton{
    
    UIButton* btnExport = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *buttonImage = [[UIImage imageNamed:@"blueButton"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"blueButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    
    [btnExport setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [btnExport setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
    btnExport.frame = CGRectMake(0, 0, 220, 46);
    [btnExport setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnExport setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    btnExport.titleLabel.shadowOffset = CGSizeMake(0, 1);
    btnExport.titleLabel.font = [[self class] boldFontOfSize:16];
    
    return btnExport;
}

+(UIButton*)greenButton{
    
    UIButton* btnExport = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *buttonImage = [[UIImage imageNamed:@"greenButton"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greenButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    
    [btnExport setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [btnExport setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
    btnExport.frame = CGRectMake(0, 0, 220, 46);
    [btnExport setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnExport setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    btnExport.titleLabel.shadowOffset = CGSizeMake(0, 1);
    btnExport.titleLabel.font = [[self class] boldFontOfSize:16];
    
    return btnExport;
}

+(UIButton*)greyButton{
    
    UIButton* btnExport = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    
    [btnExport setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [btnExport setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    
    btnExport.frame = CGRectMake(0, 0, 220, 46);
    [btnExport setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnExport setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnExport.titleLabel.shadowOffset = CGSizeMake(0, 1);
    btnExport.titleLabel.font = [[self class] boldFontOfSize:16];
    
    return btnExport;
}
//
@end
