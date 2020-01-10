//
//  RMVScrollView.h
//  RateMyView
//
//  Created by Daniel Anderton on 16/07/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol RMVScrollViewDelegate;
@interface RMVScrollView : UIScrollView
@property(nonatomic,assign) id<RMVScrollViewDelegate> layoutDelegate;
-(void)layoutView;
-(void)cleanup;
@end


@protocol RMVScrollViewDelegate <NSObject>

-(void)didLayoutView:(RMVScrollView*)scroll;

@end