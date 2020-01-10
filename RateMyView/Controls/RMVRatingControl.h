//
//  AMRatingControl.h
//  RatingControl
//


#import <UIKit/UIKit.h>

typedef void (^EditingChangedBlock)(NSUInteger rating);
typedef void (^EditingDidEndBlock)(NSUInteger rating);


@interface RMVRatingControl : UIControl
{
	UIImage *_emptyImage, *_solidImage;
    UIColor *_emptyColor, *_solidColor;
    NSInteger _maxRating;
}


#pragma mark - Getters and Setters

@property (nonatomic, assign) NSInteger rating;
@property (nonatomic, readwrite) NSUInteger starFontSize;
@property (nonatomic, readwrite) NSUInteger starWidthAndHeight;
@property (nonatomic, readwrite) NSUInteger starSpacing;
@property (nonatomic, copy) EditingChangedBlock editingChangedBlock;
@property (nonatomic, copy) EditingDidEndBlock editingDidEndBlock;

- (id)initWithLocation:(CGPoint)location andMaxRating:(NSInteger)maxRating;

- (id)initWithLocation:(CGPoint)location
            emptyColor:(UIColor *)emptyColor
            solidColor:(UIColor *)solidColor
          andMaxRating:(NSInteger)maxRating;

- (id)initWithLocation:(CGPoint)location
            emptyImage:(UIImage *)emptyImageOrNil
            solidImage:(UIImage *)solidImageOrNil
          andMaxRating:(NSInteger)maxRating;



@end
