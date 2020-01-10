//
//  InveniasPopOverController.h
//  Rate My View
//
//  Created by Daniel Anderton on 27/08/2013.
//

#import <UIKit/UIKit.h>

@interface RMVPopOverController : UIPopoverController

@property(nonatomic,strong) UIViewController* presentationView;
@property(nonatomic,assign) CGRect presentationRect;
@property(nonatomic,assign) UIPopoverArrowDirection presentionArrow;
@property(nonatomic,strong) UIBarButtonItem* presentionBarItem;
@property(nonatomic) BOOL autoRotate;
-(void)dismiss;

@end
