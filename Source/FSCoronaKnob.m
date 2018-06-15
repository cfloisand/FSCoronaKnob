//
//  FSCoronaKnob.m
//  FSCoronaKnob
//
//  Created by Christian on 2014-06-30.
//  Copyright (c) 2014 Flyingsand. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "FSCoronaKnob.h"

#define TWOPI (6.2831853071795865)
#define THREEPI_OVER2 (4.71238898038469)
#define ANGLE_EPSILON (0.00001f)
#define VALUE_MIN (0.0001f)
#define CORONA_ANIMATION_DURATION (0.24f)
#define CORONA_ANIMATION_KEY    @"coronaAnimation"
#define HIGHLIGHT_LAYER_OPACITY (0.52f)

#define DEFAULT_START_ANGLE		THREEPI_OVER2
#define DEFAULT_END_ANGLE		THREEPI_OVER2
#define DEFAULT_KNOB_VALUE		0.0
#define DEFAULT_TAP_INCREMENT	0.25
#define DEFAULT_DRAG_INCREMENT  0.01
#define DEFAULT_DRAG_SENSITIVITY 1.0
#define DEFAULT_KNOB_COLOR      [UIColor colorWithRed:221.0/255.0 green:225.0/255.0 blue:220.0/255.0 alpha:1.0]
#define DEFAULT_CORONA_COLOR    [UIColor colorWithRed:141.0/255.0 green:196.0/255.0 blue:223.0/255.0 alpha:1.0]
#define DEFAULT_BACKGROUND_COLOR [UIColor clearColor]
#define DEFAULT_KNOB_WIDTH		4.0
#define DEFAULT_CORONA_WIDTH    4.0

#define PRACTICALLY_ZERO(num)   (((num) < VALUE_MIN) || (fabs(1.0 - (num)) < VALUE_MIN))
#define PRACTICALLY_EQUAL(num1, num2) (fabs((num1) - (num2)) < ANGLE_EPSILON)


inline static CGFloat
FSCalculateKnobRadius(CGFloat knobSize, CGFloat coronaWidth) {
    return (knobSize / 2.0) - coronaWidth;
}

inline static CGFloat
FSCalculateKnobAngleRange(CGFloat startAngle, CGFloat endAngle) {
    if (fabs(endAngle - startAngle) < FLT_MIN) {
        // NOTE: Prevents value wrapping when startAngle and endAngle are the same.
        return (TWOPI - ANGLE_EPSILON);
    } else {
        CGFloat diff = endAngle - startAngle;
        return (diff > TWOPI ? diff-TWOPI : (diff <= 0.0 ? diff+TWOPI : diff));
    }
}


#pragma mark - FSCoronaKnob
@implementation FSCoronaKnob {
    CAShapeLayer * __weak _backgroundLayer;
    CAShapeLayer * __weak _knobLayer;
    CAShapeLayer * __weak _coronaLayer;
    CAShapeLayer * __weak _highlightLayer;
    
    CGPoint _centerPoint;
    CGFloat _prevValue;
    CGFloat _angleRange;
    CGFloat _radius;
    
    BOOL _isDragging;
    CGFloat _dragCounter;
    
    NSLayoutConstraint * _widthConstraint;
    NSLayoutConstraint * _heightConstraint;
    
    BOOL _isInitializing;
}

- (instancetype)init {
	return (self = [self initWithFrame:CGRectZero]);
}

- (instancetype)initWithFrame:(CGRect)frame {
    NSAssert(frame.size.width == frame.size.height, @"Corona Knob's width and height must be the same.");
    
    self = [super initWithFrame:frame];
    if (self) {
        [self __commonInitWithKnobDimension:frame.size.width];
        self.translatesAutoresizingMaskIntoConstraints = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSAssert(NO, @"initWithCoder: not implemented.");
    return (self = [super initWithCoder:aDecoder]);
}

- (instancetype)initWithSize:(CGSize)size delegate:(id<FSCoronaKnobDelegate>)delegate {
    NSAssert(size.width == size.height, @"Corona Knob's width and height must be the same.");
    
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _widthConstraint = [self.widthAnchor constraintEqualToConstant:size.width];
        _heightConstraint = [self.heightAnchor constraintEqualToConstant:size.height];
        _widthConstraint.active = YES;
        _heightConstraint.active = YES;
        
        _delegate = delegate;
        
        [self __commonInitWithKnobDimension:size.width];
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)__commonInitWithKnobDimension:(CGFloat)dim {
    _startAngle = DEFAULT_START_ANGLE;
    _endAngle = DEFAULT_END_ANGLE;
    _angleRange = TWOPI - ANGLE_EPSILON;
    _value = DEFAULT_KNOB_VALUE;
    _tapIncrement = DEFAULT_TAP_INCREMENT;
    _dragIncrement = DEFAULT_DRAG_INCREMENT;
    _dragSensitivity = DEFAULT_DRAG_SENSITIVITY;
    _knobColor = DEFAULT_KNOB_COLOR;
    _coronaColor = DEFAULT_CORONA_COLOR;
    _knobBackgroundColor = DEFAULT_BACKGROUND_COLOR;
    _knobWidth = DEFAULT_KNOB_WIDTH;
    _coronaWidth = DEFAULT_CORONA_WIDTH;
    _radius = FSCalculateKnobRadius(dim, _coronaWidth);
    _valueWrapping = FSCoronaKnobValueWrapNone;
    _prevValue = _value;
    
    _isInitializing = YES;
    _isDragging = NO;
    _tapped = YES;
    _dragCounter = 0.0;
    
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    
    CAShapeLayer *backLayer = [CAShapeLayer layer];
    backLayer.fillColor = self.knobBackgroundColor.CGColor;
    backLayer.opacity = 1.0;
    backLayer.zPosition = 0.0;
    [self.layer addSublayer:backLayer];
    _backgroundLayer = backLayer;
    
    CAShapeLayer *knobLayer = [CAShapeLayer layer];
    knobLayer.fillColor = nil;
    knobLayer.strokeColor = self.knobColor.CGColor;
    knobLayer.opacity = 1.0;
    knobLayer.zPosition = 1.0;
    knobLayer.lineWidth = self.knobWidth;
    knobLayer.lineJoin = kCALineJoinMiter;
    [self.layer addSublayer:knobLayer];
    _knobLayer = knobLayer;
    
    CAShapeLayer *coronaLayer = [CAShapeLayer layer];
    coronaLayer.strokeColor = self.coronaColor.CGColor;
    coronaLayer.fillColor = nil;
    coronaLayer.opacity = 1.0;
    coronaLayer.zPosition = 2.0;
    coronaLayer.lineWidth = self.coronaWidth;
    coronaLayer.lineJoin = kCALineJoinMiter;
    [self.layer addSublayer:coronaLayer];
    _coronaLayer = coronaLayer;
    _coronaLayer.strokeEnd = 0.0;
    // NOTE: Turn off implicit animation for strokeColor, because it will interfere with
    // the corona path animation for the special case when the knob is touched during animation
    // when the value returns to 0. See note in draw animated method.
    _coronaLayer.actions = @{@"strokeColor": [NSNull null]};
    
    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.font = [UIFont systemFontOfSize:12.0];
    valueLabel.textColor = self.coronaColor;
    valueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:valueLabel];
    _valueLabel = valueLabel;
}

- (CGSize)intrinsicContentSize {
    return self.frame.size;
}

- (void)setNeedsDisplay {
    self.value = self.value; // NOTE: Force knob to draw.
    [super setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _valueLabel.frame = self.bounds;
    _centerPoint = [self.superview convertPoint:self.center toView:self];
    
    [self __updateAllLayers];
    
    if (_isInitializing) {
        [self __updateValueLabelAndCoronaColor];
        _isInitializing = NO;
    }
}

#pragma mark - Properties
- (void)setDelegate:(id<FSCoronaKnobDelegate>)delegate {
    _delegate = delegate;
    [self __updateValueLabelAndCoronaColor];
}

- (void)setStartAngle:(CGFloat)startAngle {
	_startAngle = startAngle;
    _angleRange = FSCalculateKnobAngleRange(_startAngle, _endAngle);
}

- (void)setEndAngle:(CGFloat)endAngle {
	_endAngle = endAngle;
	_angleRange = FSCalculateKnobAngleRange(_startAngle, _endAngle);
}

- (void)setValue:(CGFloat)value {
    if (!PRACTICALLY_EQUAL(_value, value)) {
        _value = value;
        
        if (_value >= 1.0) {
            _value = (self.valueWrapping & FSCoronaKnobValueWrapPositive ? _value-1.0 : 1.0);
        } else if (_value <= 0.0) {
            _value = (self.valueWrapping & FSCoronaKnobValueWrapNegative ? _value+1.0 : 0.0);
        }
        
        [self __updateValueLabelAndCoronaColor];
        [self __drawCoronaAnimated:_tapped];
    }
}

- (void)setTapIncrement:(CGFloat)tapIncrement {
    _tapIncrement = (tapIncrement > 1.0 ? 1.0 :
                     (tapIncrement < 0.0 ? 0.0 : tapIncrement));
}

- (void)setDragIncrement:(CGFloat)dragIncrement {
    _dragIncrement = (dragIncrement > 1.0 ? 1.0 :
                      (dragIncrement < 0.0 ? 0.0 : dragIncrement));
}

- (void)setDragSensitivity:(CGFloat)dragSensitivity {
    _dragSensitivity = (dragSensitivity > 1.0 ? 1.0:
                        (dragSensitivity < 0.0 ? 0.0 : dragSensitivity));
}

- (void)setKnobWidth:(CGFloat)knobWidth {
	_knobWidth = knobWidth;
    _knobLayer.lineWidth = knobWidth;
	if (_highlightLayer) {
		_highlightLayer.lineWidth = knobWidth;
	}
    
    [self __updateBackgroundLayer];
}

- (void)setCoronaWidth:(CGFloat)coronaWidth {
	_coronaWidth = coronaWidth;
	if (_coronaLayer) {
		_coronaLayer.lineWidth = coronaWidth;
	}
    
    _radius = FSCalculateKnobRadius(self.frame.size.width, _coronaWidth);
    [self __updateBackgroundLayer];
}

- (void)setKnobColor:(UIColor *)knobColor {
    _knobColor = knobColor;
    _knobLayer.strokeColor = knobColor.CGColor;
}

- (void)setCoronaColor:(UIColor *)coronaColor {
	_coronaColor = coronaColor;
    _valueLabel.textColor = coronaColor;
	if (_coronaLayer) {
		_coronaLayer.strokeColor = coronaColor.CGColor;
	}
}

- (void)setKnobBackgroundColor:(UIColor *)knobBackgroundColor {
    _knobBackgroundColor = knobBackgroundColor;
    _backgroundLayer.fillColor = knobBackgroundColor.CGColor;
}

- (void)setFrame:(CGRect)frame {
    if (!CGRectEqualToRect(frame, self.frame)) {
        NSAssert(frame.size.width == frame.size.height, @"Corona Knob's width and height must be the same.");
        
        super.frame = frame;
        _valueLabel.frame = self.bounds;
        _centerPoint = [self.superview convertPoint:self.center toView:self];
        _radius = FSCalculateKnobRadius(self.frame.size.width, _coronaWidth);
        
        if (_widthConstraint) {
            _widthConstraint.constant = self.frame.size.width;
        }
        if (_heightConstraint) {
            _heightConstraint.constant = self.frame.size.height;
        }
        
        [self __updateAllLayers];
    }
}

- (void)setBounds:(CGRect)bounds {
    if (!CGRectEqualToRect(bounds, self.bounds)) {
        NSAssert(bounds.size.width == bounds.size.height, @"Corona Knob's width and height must be the same.");
        
        super.bounds = bounds;
        _valueLabel.frame = self.bounds;
        _centerPoint = [self.superview convertPoint:self.center toView:self];
        _radius = FSCalculateKnobRadius(self.bounds.size.width, _coronaWidth);
        
        if (_widthConstraint) {
            _widthConstraint.constant = self.bounds.size.width;
        }
        if (_heightConstraint) {
            _heightConstraint.constant = self.bounds.size.height;
        }
        
        [self __updateAllLayers];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    super.backgroundColor = [UIColor clearColor];
}

- (void)setOpaque:(BOOL)opaque {
    // NOTE: Allowing the opaque property to be YES would mess up drawing of the control.
    super.opaque = NO;
}

- (void)reset {
    self.value = 0.0;
    _dragCounter = 0.0;
}

#pragma mark - Interaction
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_highlightLayer == nil) {
		CAShapeLayer *highlightLayer = [CAShapeLayer layer];
		CGPathRef highlightPath = CGPathCreateCopy(_coronaLayer.path);
		highlightLayer.frame = self.bounds;
		highlightLayer.strokeColor = [[UIColor whiteColor] CGColor];
		highlightLayer.fillColor = nil;
        highlightLayer.opacity = HIGHLIGHT_LAYER_OPACITY;
		highlightLayer.lineWidth = self.coronaWidth;
		highlightLayer.lineJoin = kCALineJoinMiter;
		highlightLayer.zPosition = 3.0;
		highlightLayer.path = highlightPath;
		[self.layer addSublayer:highlightLayer];
		_highlightLayer = highlightLayer;
		CGPathRelease(highlightPath);
	}
	
	_highlightLayer.hidden = NO;
	[_highlightLayer setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[touches allObjects] firstObject];
    if (touch == nil) {
        [super touchesMoved:touches withEvent:event];
        return;
    }
    
    if (touch.view == self && _dragIncrement > 0.0) {
        _isDragging = YES;
        _tapped = NO;
        
        CGFloat diffX = [touch locationInView:self].x - [touch previousLocationInView:self].x;
        // Swap y direction so that dragging up increases knob's value and dragging down decreases it.
        CGFloat diffY = [touch previousLocationInView:self].y - [touch locationInView:self].y;
        CGFloat diff = (fabs(diffX) >= fabs(diffY) ? diffX : diffY);
        
        if (diff > 0.0) {
            _dragCounter += _dragSensitivity;
            if (_dragCounter >= 1.0) {
                self.value += _dragIncrement;
                _dragCounter -= 1.0;
            }
        } else if (diff < 0.0) {
            _dragCounter -= _dragSensitivity;
            if (_dragCounter <= -1.0) {
                self.value -= _dragIncrement;
                _dragCounter += 1.0;
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[touches allObjects] firstObject];
    if (touch == nil) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    
    CGPoint touchPoint = [touch locationInView:self];
    
    if ([self pointInside:touchPoint withEvent:event] && !_isDragging) {
        _tapped = YES;
        _isDragging = NO;
		if (self.value < 1.0) {
			self.value += _tapIncrement;
		}
        
        _dragCounter = 0.0;
    }
    
    _isDragging = NO;
	_highlightLayer.hidden = YES;
	[_highlightLayer setNeedsDisplay];
}

#pragma mark - Private methods
- (void)__updateValueLabelAndCoronaColor {
    if (self.delegate && [self.delegate respondsToSelector:@selector(coronaKnob:stringForValue:)]) {
        _valueLabel.text = [self.delegate coronaKnob:self stringForValue:self.value];
    } else {
        _valueLabel.text = [NSString stringWithFormat:@"%1.2f", self.value];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(coronaKnob:coronaColorForValue:)]) {
        UIColor *color = [self.delegate coronaKnob:self coronaColorForValue:self.value];
        if (color) {
            self.coronaColor = color;
        } else {
            self.coronaColor = DEFAULT_CORONA_COLOR;
        }
        
        _valueLabel.textColor = self.coronaColor;
    }
}

- (void)__drawCoronaAnimated:(BOOL)animated {
    if (!animated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        _coronaLayer.strokeEnd = _value;
        [CATransaction commit];
        
        [_coronaLayer setNeedsDisplay];
    } else {
        BOOL valueIsZero = NO;
        BOOL valueWrapped = NO;
        CGFloat strokeTarget = _value;
        
        if (PRACTICALLY_ZERO(_value) && PRACTICALLY_EQUAL(_startAngle, _endAngle)) {
            valueIsZero = YES;
            strokeTarget = _endAngle - ANGLE_EPSILON;
        } else if (_value < _prevValue) {
            valueWrapped = YES;
            strokeTarget = _endAngle - ANGLE_EPSILON;
        }
        
        CAAnimationGroup *coronaAnimation = [CAAnimationGroup animation];
        CABasicAnimation *strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeAnimation.duration = CORONA_ANIMATION_DURATION;
        strokeAnimation.toValue = @(strokeTarget);
        strokeAnimation.fillMode = kCAFillModeForwards;
        strokeAnimation.beginTime = 0.0;
        
        // NOTE: Removing an animation that may currently be running from a previous tap
        // ensures correct animation. E.g. when the value is 0 (and the start/end anges are the same),
        // the animation would otherwise be interpolated in reverse to reach the current value
        // set for this tap.
        if ([_coronaLayer animationForKey:CORONA_ANIMATION_KEY]) {
            [_coronaLayer removeAllAnimations];
            
            if (PRACTICALLY_ZERO(_prevValue)) {
                strokeAnimation.fromValue = @(0.0);
            }
        }
        
        _coronaLayer.strokeEnd = _value;
        
        if (valueIsZero && (self.valueWrapping & FSCoronaKnobValueWrapPositive)) {
            strokeAnimation.duration *= 2;
            CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeAnimation.duration = strokeAnimation.duration;
            fadeAnimation.toValue = @(0.0);
            fadeAnimation.fillMode = kCAFillModeForwards;
            fadeAnimation.beginTime = 0.0;
            
            coronaAnimation.animations = @[strokeAnimation, fadeAnimation];
            coronaAnimation.duration = strokeAnimation.duration + fadeAnimation.duration;
        } else if (valueWrapped) {
            strokeAnimation.duration /= 2.0;
            CABasicAnimation *wrapAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            wrapAnimation.duration = CORONA_ANIMATION_DURATION;
            wrapAnimation.fromValue = @(0.0);
            wrapAnimation.toValue = @(_value);
            wrapAnimation.fillMode = kCAFillModeForwards;
            wrapAnimation.beginTime = strokeAnimation.duration;
            
            coronaAnimation.animations = @[strokeAnimation, wrapAnimation];
            coronaAnimation.duration = strokeAnimation.duration + wrapAnimation.duration;
        } else {
            coronaAnimation.animations = @[strokeAnimation];
            coronaAnimation.duration = strokeAnimation.duration;
        }
        
        [_coronaLayer addAnimation:coronaAnimation forKey:CORONA_ANIMATION_KEY];
    }
    
    _prevValue = _value;
}

- (void)__updateBackgroundLayer {
    // NOTE: Inset the background layer to make sure it doesn't spill out beyond the knob.
    CGFloat insetAmount = MAX(_knobWidth, _coronaWidth) + 0.5;
    CGPathRef backPath = CGPathCreateWithEllipseInRect(CGRectInset(self.bounds, insetAmount, insetAmount), NULL);
    _backgroundLayer.frame = self.bounds;
    _backgroundLayer.path = backPath;
    CGPathRelease(backPath);
}

- (void)__updateKnobLayer {
    _knobLayer.frame = self.bounds;
    _knobLayer.path = [[UIBezierPath bezierPathWithArcCenter:_centerPoint
                                                      radius:_radius
                                                  startAngle:0.0
                                                    endAngle:TWOPI
                                                   clockwise:YES] CGPath];
}

- (void)__updateCoronaLayer {
    _coronaLayer.frame = self.bounds;
    _coronaLayer.path = [[UIBezierPath bezierPathWithArcCenter:_centerPoint
                                                        radius:_radius
                                                    startAngle:_startAngle
                                                      endAngle:_endAngle - ANGLE_EPSILON
                                                     clockwise:YES] CGPath];
}

- (void)__updateAllLayers {
    [self __updateBackgroundLayer];
    [self __updateKnobLayer];
    [self __updateCoronaLayer];
}

@end
