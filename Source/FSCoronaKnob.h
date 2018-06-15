//
//  FSCoronaKnob.h
//  FSCoronaKnob
//
//  Created by Christian on 2014-06-30.
//  Copyright (c) 2014 Flyingsand. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef __IPHONE_7_0
#error "This project requires iOS SDK 7.0 and later."
#endif

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "Compiling without ARC is not supported."
#endif


#pragma mark - Protocols

@class FSCoronaKnob;

@protocol FSCoronaKnobDelegate <NSObject>

@optional
- (NSString *)coronaKnob:(FSCoronaKnob *)knob stringForValue:(CGFloat)value;
- (UIColor *)coronaKnob:(FSCoronaKnob *)knob coronaColorForValue:(CGFloat)value;

@end


typedef NS_OPTIONS(NSUInteger, FSCoronaKnobValueWrapping) {
    /*! No wrapping; value is clamped to [0.0..1.0). */
	FSCoronaKnobValueWrapNone,
    /*! Value wraps around when it exceeds 1.0. */
	FSCoronaKnobValueWrapPositive,
    /*! Value wraps around when it is less than 0.0. */
	FSCoronaKnobValueWrapNegative,
};


#pragma mark - Interface

@interface FSCoronaKnob : UIControl

/*! @brief The angle in radians where the corona starts, corresponding to the value of 0.0.
	@details The coordinate system of the unit circle is as follows: 0 or 2pi radians is on the right side, increasing
	in a clockwise direction around the circle. Default is 3*pi/2. */
@property (nonatomic) CGFloat startAngle;
/*! @brief The angle in radians where the corona ends, corresponding to the value of 1.0.
	@details The coordinate system of the unit circle is as follows: 0 or 2pi radians is on the right side, increasing
	in a clockwise direction around the circle. Default is 3*pi/2. */
@property (nonatomic) CGFloat endAngle;

/*! @brief The value of the knob. This value is always between [0.0 .. 1.0). */
@property (nonatomic) CGFloat value;
/*! @brief The amount to increment \c value by when the control is tapped (must be between 0.0 and 1.0). */
@property (nonatomic) CGFloat tapIncrement;
/*! @brief The amount \c value is changed by when the control is dragged (must be between 0.0 and 1.0). */
@property (nonatomic) CGFloat dragIncrement;
/*! @brief The sensitivity of dragging over the knob to change its value (must be between 0.0 and 1.0).
    @details A lower sensitivity value means the drag touch gesture has to move further to trigger a change in the knob's value
    by \c dragIncrement. The default is 1.0 for maximum sensitivity. */
@property (nonatomic) CGFloat dragSensitivity;
/*! @brief Returns YES if the control's value was changed by a single tap, otherwise NO (i.e. control was dragged). */
@property (nonatomic, readonly) BOOL tapped;
/*! @brief Bitmask that defines the wrapping mode for the knob's value.
	@details Default is \c CFCoronaKnobValueWrapNone (value is clamped and does not wrap). */
@property (nonatomic) FSCoronaKnobValueWrapping valueWrapping;

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

/*! @brief The value label at the center of the kno. */
@property (nonatomic, weak, readonly) UILabel *valueLabel;

@property (nonatomic, weak) id<FSCoronaKnobDelegate> delegate;


/*! @brief Initializes the corona knob with the given size and delegate. \c delegate may be nil. */
- (instancetype)initWithSize:(CGSize)size delegate:(id<FSCoronaKnobDelegate>)delegate;

/*! @brief Sets value to 0 and clears the corona. */
- (void)reset;

@end
