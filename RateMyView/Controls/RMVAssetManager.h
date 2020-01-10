//
//  RMVAssetManager.h
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kIsiOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
@interface RMVAssetManager : NSObject

+(UIFont*)headingFontOfSize:(CGFloat)size;
+(UIFont*)italicFontOfSize:(CGFloat)size;
+(UIFont*)bodyFontOfSize:(CGFloat)size;
+(UIFont*)boldFontOfSize:(CGFloat)size;
+(UIButton*)blueButton;
+(UIButton*)greenButton;
+(UIButton*)greyButton;
@end
