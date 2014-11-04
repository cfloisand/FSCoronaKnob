/*!
 
 @file		CFCoronaKnob.h
 @author	Christian Floisand
 @date		Created: 2014-06-30
            Modified: 2014-10-01
 @copyright	Copyright (C) 2014 Christian Floisand. All rights reserved.
            Unauthorized copying of this file, via any medium is strictly prohibited.
 
 @details   A circular knob whose value is represented by a corona that encloses its value 
            label in the center. The knob's value can be modified by tapping like a regular button
            or by dragging across it (similar to the behavior of an audio knob).
			Increasing values always draws the corona in a clockwise direction around the knob.
 
 _________________________________________________________________________________________________ */

#import <UIKit/UIKit.h>

#ifndef __IPHONE_7_0
#error "This project requires iOS SDK 7.0 and later."
#endif

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "Compiling without ARC is not supported."
#endif


#pragma mark - Protocols

@class CFCoronaKnob;

@protocol CFCoronaKnobDelegate <NSObject>

@optional
- (NSString *)coronaKnob:(CFCoronaKnob *)knob stringForValue:(CGFloat)value;
- (UIColor *)coronaKnob:(CFCoronaKnob *)knob coronaColorForValue:(CGFloat)value;

@end


typedef NS_OPTIONS(NSUInteger, CFCoronaKnobValueWrapping) {
	CFCoronaKnobValueWrapNone, /*! No wrapping; value is clamped to [0.0..1.0). */
	CFCoronaKnobValueWrapPositive, /*! Value wraps around when it exceeds 1.0. */
	CFCoronaKnobValueWrapNegative, /*! Value wraps around when it is less than 0.0. */
};


#pragma mark - Interface

@interface CFCoronaKnob : UIControl
{
@protected
    CAShapeLayer *__weak _backgroundLayer;
    CAShapeLayer *__weak _knobLayer;
	CAShapeLayer *__weak _coronaLayer;
	CAShapeLayer *__weak _highlightLayer;
    UILabel *__weak _valueLabel;
}

/*! @brief Initializes the corona knob with the given frame and delegate (may be nil). */
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<CFCoronaKnobDelegate>)theDelegate;

@property (weak, nonatomic) id<CFCoronaKnobDelegate> delegate;

/*! @brief The angle in radians where the corona starts (i.e. represents the value of 0.0).
	@details Default is 3*pi/2.
	@discussion The coordinate system of the unit circle is as follows: 0 or 2pi radians is on the right side, increasing
	in a clockwise direction around the circle. */
@property (nonatomic) CGFloat startAngle;
/*! @brief The angle in radians where the corona ends (i.e. represents the value of 1.0).
	@details Default is 3*pi/2.
	@discussion The coordinate system of the unit circle is as follows: 0 or 2pi radians is on the right side, increasing
	in a clockwise direction around the circle.*/
@property (nonatomic) CGFloat endAngle;

/*! @brief The value of the knob. This value is always between [0.0 .. 1.0). */
@property (nonatomic) CGFloat value;
/*! @brief The amount to increment @c value by when the control is tapped (must be between 0.0 and 1.0). */
@property (nonatomic) CGFloat tapIncrement;
/*! @brief The amount @c value is changed by when the control is dragged (must be between 0.0 and 1.0). */
@property (nonatomic) CGFloat dragIncrement;
/*! @brief The sensitivity of dragging over the knob to change its value (must be between 0.0 and 1.0).
    @details A lower sensitivity value means the drag touch gesture has to move further to trigger a change in the knob's value
    by \c dragIncrement. The default is 1.0 for maximum sensitivity. */
@property (nonatomic) CGFloat dragSensitivity;
/*! @brief Returns YES if the control's value was changed by a single tap, otherwise NO (i.e. control was dragged). */
@property (nonatomic, readonly) BOOL tapped;
/*! @brief Bitmask that defines the wrapping mode for the knob's value.
	@details Default is CFCoronaKnobValueWrapNone; i.e. value is clamped and does not wrap. */
@property (nonatomic) CFCoronaKnobValueWrapping valueWrapping;

/*! @brief The width of the control's underlying knob circle (default is 1.0). */
@property (nonatomic) CGFloat knobWidth;
/*! @brief The width of the corona, which represents the current value. (default is 2.0). */
@property (nonatomic) CGFloat coronaWidth;
/*! @brief The color of the underlying knob (default is light gray). */
@property (nonatomic, strong) UIColor *knobColor;
/*! @brief The color of the overlaying arc that indicates the control's value (default is yellow). */
@property (nonatomic, strong) UIColor *coronaColor;
/*! @brief The color of the inner knob (default is transparent). */
@property (nonatomic, strong) UIColor *knobBackgroundColor;

/*! @brief Sets value to 0 and clears the corona. */
- (void)reset;

/*! @brief Sets the font used by the label in the center of the knob. */
- (void)setValueLabelFont:(UIFont *)font;

@end
