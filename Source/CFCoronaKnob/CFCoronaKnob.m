//
//  File:		CFCoronaKnob.m
//  Author:		Christian Floisand
//	Created:	2014-06-30
//	Modified:	2015-02-07
//

#import <QuartzCore/QuartzCore.h>
#import "CFCoronaKnob.h"

#define TWOPI (6.2831853071795865)
#define THREEPI_OVER2 (4.71238898038469)
#define ANGLE_EPSILON (0.00001f)
#define VALUE_MIN (0.0001f)
#define CORONA_ANIMATION_DURATION (0.24f)
#define CORONA_ANIMATION_KEY    @"coronaAnimation"
#define HIGHLIGHT_LAYER_OPACITY (0.52f)

#define DEFAULT_START_ANGLE		THREEPI_OVER2
#define DEFAULT_END_ANGLE		THREEPI_OVER2
#define DEFAULT_KNOB_VALUE		0.f
#define DEFAULT_TAP_INCREMENT	0.25f
#define DEFAULT_DRAG_INCREMENT  0.01f
#define DEFAULT_DRAG_SENSITIVITY 1.f
#define DEFAULT_KNOB_COLOR      [UIColor colorWithRed:221.f/255.f green:225.f/255.f blue:220.f/255.f alpha:1.f]
#define DEFAULT_CORONA_COLOR    [UIColor colorWithRed:141.f/255.f green:196.f/255.f blue:223.f/255.f alpha:1.f]
#define DEFAULT_BACKGROUND_COLOR [UIColor clearColor]
#define DEFAULT_KNOB_WIDTH		4.f
#define DEFAULT_CORONA_WIDTH    4.f

#define PRACTICALLY_ZERO(num)   (((num) < VALUE_MIN) || (fabsf(1.f - (num)) < VALUE_MIN))
#define PRACTICALLY_EQUAL(num1, num2) (fabsf((num1) - (num2)) < ANGLE_EPSILON)


@interface CFCoronaKnob () {
    CGPoint _centerPoint;
	CGFloat _prevValue;
	CGFloat _angleRange;
    CGFloat _radius;
    
    BOOL _isDragging;
    CGFloat _dragCounter;
}
@property (nonatomic, copy) CGFloat (^calculateAngleRange)(void);
@end


@implementation CFCoronaKnob

- (instancetype)init
{
	return (self = [self initWithFrame:CGRectZero delegate:nil]);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return (self = [self initWithFrame:frame delegate:nil]);
}

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<CFCoronaKnobDelegate>)theDelegate
{
    NSAssert(frame.size.width == frame.size.height, @"Corona Knob's width and height must be the same.");
    
    self = [super initWithFrame:frame];
    if (self) {
        _delegate = theDelegate;
        
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
		_valueWrapping = CFCoronaKnobValueWrapNone;
        _radius = self.bounds.size.width / 2.f - _coronaWidth;
		_prevValue = _value;
        
        _isDragging = NO;
        _tapped = YES;
        _dragCounter = 0.f;
        
        __weak typeof(self) weakSelf = self;
        _calculateAngleRange = ^CGFloat (void) {
            typeof(self) strongSelf = weakSelf;
            if (fabsf(strongSelf.endAngle - strongSelf.startAngle) < FLT_MIN) {
                // NOTE: Prevents value wrapping when startAngle and endAngle are the same.
                return (TWOPI - ANGLE_EPSILON);
            } else {
                CGFloat diff = strongSelf.endAngle - strongSelf.startAngle;
                return (diff > TWOPI ? diff-TWOPI : (diff <= 0.f ? diff+TWOPI : diff));
            }
        };
        
        self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)didMoveToSuperview
{
    if (self.superview != nil) {
        _centerPoint = [self.superview convertPoint:self.center toView:self];
        
        CAShapeLayer *backLayer = [CAShapeLayer layer];
        // NOTE: Inset the background layer to make sure it doesn't spill out beyond the knob.
        CGFloat insetAmount = MAX(_knobWidth, _coronaWidth) + 0.5f;
        CGPathRef backPath = CGPathCreateWithEllipseInRect(CGRectInset(self.bounds, insetAmount, insetAmount), NULL);
        backLayer.frame = self.bounds;
        backLayer.fillColor = self.knobBackgroundColor.CGColor;
        backLayer.opacity = 1.f;
        backLayer.zPosition = 0.f;
        backLayer.path = backPath;
        [self.layer addSublayer:backLayer];
        _backgroundLayer = backLayer;
        CGPathRelease(backPath);
        
        CAShapeLayer *knobLayer = [CAShapeLayer layer];
        knobLayer.frame = self.bounds;
        knobLayer.fillColor = nil;
        knobLayer.strokeColor = self.knobColor.CGColor;
        knobLayer.opacity = 1.f;
        knobLayer.zPosition = 1.f;
        knobLayer.lineWidth = self.knobWidth;
        knobLayer.lineJoin = kCALineJoinMiter;
        knobLayer.path = [[UIBezierPath bezierPathWithArcCenter:_centerPoint
                                                         radius:_radius
                                                     startAngle:0.f
                                                       endAngle:TWOPI
                                                      clockwise:YES] CGPath];
        [self.layer addSublayer:knobLayer];
        _knobLayer = knobLayer;
        
        CAShapeLayer *coronaLayer = [CAShapeLayer layer];
        coronaLayer.frame = self.bounds;
        coronaLayer.strokeColor = self.coronaColor.CGColor;
        coronaLayer.fillColor = nil;
        coronaLayer.opacity = 1.f;
        coronaLayer.zPosition = 2.f;
        coronaLayer.lineWidth = self.coronaWidth;
        coronaLayer.lineJoin = kCALineJoinMiter;
        coronaLayer.path = [[UIBezierPath bezierPathWithArcCenter:_centerPoint
                                                          radius:_radius
                                                      startAngle:_startAngle
                                                        endAngle:_endAngle - ANGLE_EPSILON
                                                       clockwise:YES] CGPath];
        [self.layer addSublayer:coronaLayer];
        _coronaLayer = coronaLayer;
        _coronaLayer.strokeEnd = 0.f;
        // NOTE: Turn off implicit animation for strokeColor, because it will interfere with
        // the corona path animation for the special case when the knob is touched during animation
        // when the value returns to 0. See note in draw animated method.
        _coronaLayer.actions = @{@"strokeColor": [NSNull null]};
        
        // Value label added last as a subview so it appears over the top of the other layers.
        UILabel *valueLabel = [[UILabel alloc] init];
        valueLabel.font = [UIFont systemFontOfSize:11.f];
        valueLabel.textColor = self.coronaColor;
        valueLabel.textAlignment = NSTextAlignmentCenter;
        valueLabel.frame = self.bounds;
        [self addSubview:valueLabel];
        _valueLabel = valueLabel;
        
        [self cf_updateCoronaStringForValue];
    }
    
    [super didMoveToSuperview];
}

- (void)removeFromSuperview
{
    [_valueLabel removeFromSuperview];
    [super removeFromSuperview];
}

- (CGSize)intrinsicContentSize
{
    return self.frame.size;
}

- (void)setNeedsDisplay
{
    [self cf_updateCoronaStringForValue];
    [self cf_updateCoronaColorForValue];
    [super setNeedsDisplay];
}

#pragma mark - Properties

- (void)setDelegate:(id<CFCoronaKnobDelegate>)delegate
{
    _delegate = delegate;
    [self cf_updateCoronaStringForValue];
    [self cf_updateCoronaColorForValue];
}

- (void)setStartAngle:(CGFloat)startAngle
{
	_startAngle = startAngle;
    _angleRange = self.calculateAngleRange();
}

- (void)setEndAngle:(CGFloat)endAngle
{
	_endAngle = endAngle;
	_angleRange = self.calculateAngleRange();
}

- (void)setValue:(CGFloat)value
{
	_value = value;
	
	if (_value >= 1.f) {
		_value = (self.valueWrapping & CFCoronaKnobValueWrapPositive ? _value-1.f : 1.f);
	} else if (_value < 0.f) {
		_value = (self.valueWrapping & CFCoronaKnobValueWrapNegative ? _value+1.f : 0.f);
	}
    
    [self cf_updateCoronaColorForValue];
}

- (void)setTapIncrement:(CGFloat)tapIncrement
{
    _tapIncrement = (tapIncrement > 1.f ? 1.f :
                     (tapIncrement < 0.f ? 0.f : tapIncrement));
}

- (void)setDragIncrement:(CGFloat)dragIncrement
{
    _dragIncrement = (dragIncrement > 1.f ? 1.f :
                      (dragIncrement < 0.f ? 0.f : dragIncrement));
}

- (void)setDragSensitivity:(CGFloat)dragSensitivity
{
    _dragSensitivity = (dragSensitivity > 1.f ? 1.f:
                        (dragSensitivity < 0.f ? 0.f : dragSensitivity));
}

- (void)setKnobWidth:(CGFloat)knobWidth
{
	_knobWidth = knobWidth;
    _knobLayer.lineWidth = knobWidth;
	if (_highlightLayer) {
		_highlightLayer.lineWidth = knobWidth;
	}
}

- (void)setCoronaWidth:(CGFloat)coronaWidth
{
	_coronaWidth = coronaWidth;
	if (_coronaLayer) {
		_coronaLayer.lineWidth = coronaWidth;
	}
}

- (void)setKnobColor:(UIColor *)knobColor
{
    _knobColor = knobColor;
    _knobLayer.strokeColor = knobColor.CGColor;
}

- (void)setCoronaColor:(UIColor *)coronaColor
{
	_coronaColor = coronaColor;
    _valueLabel.textColor = coronaColor;
	if (_coronaLayer) {
		_coronaLayer.strokeColor = coronaColor.CGColor;
	}
}

- (void)setKnobBackgroundColor:(UIColor *)knobBackgroundColor
{
    _knobBackgroundColor = knobBackgroundColor;
    _backgroundLayer.fillColor = knobBackgroundColor.CGColor;
}

- (void)setFrame:(CGRect)frame
{
    NSAssert(frame.size.width == frame.size.height, @"Corona Knob's width and height must be the same.");
    super.frame = frame;
    _radius = self.bounds.size.width / 2.f - _coronaWidth;
}

- (void)setBounds:(CGRect)bounds
{
    NSAssert(bounds.size.width == bounds.size.height, @"Corona Knob's width and height must be the same.");
    super.bounds = bounds;
    _radius = self.bounds.size.width / 2.f - _coronaWidth;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    super.backgroundColor = [UIColor clearColor];
}

- (void)setOpaque:(BOOL)opaque
{
    // NOTE: Allowing the opaque property to be YES would mess up drawing of the control.
    super.opaque = NO;
}

- (void)reset
{
    self.value = 0.f;
    _dragCounter = 0.f;
    [self cf_drawImmediateCorona];
    [self cf_updateCoronaStringForValue];
}

- (void)setValueLabelFont:(UIFont *)font
{
    if (_valueLabel) {
        _valueLabel.font = font;
    }
}

#pragma mark - Interaction

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	if ( ! _highlightLayer ) {
		CAShapeLayer *highlightLayer = [CAShapeLayer layer];
		CGPathRef highlightPath = CGPathCreateCopy(_knobLayer.path);
		highlightLayer.frame = self.bounds;
		highlightLayer.strokeColor = [[UIColor whiteColor] CGColor];
		highlightLayer.fillColor = nil;
        highlightLayer.opacity = HIGHLIGHT_LAYER_OPACITY;
		highlightLayer.lineWidth = self.knobWidth;
		highlightLayer.lineJoin = kCALineJoinMiter;
		highlightLayer.zPosition = 3.f;
		highlightLayer.path = highlightPath;
		[self.layer addSublayer:highlightLayer];
		_highlightLayer = highlightLayer;
		CGPathRelease(highlightPath);
	}
	
	_highlightLayer.hidden = NO;
	[_highlightLayer setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] firstObject];
    if (touch == nil) {
        [super touchesMoved:touches withEvent:event];
        return;
    }
    
    if (touch.view == self && _dragIncrement > 0.f) {
        CGFloat diffX = [touch locationInView:self].x - [touch previousLocationInView:self].x;
        // Swap y direction so that dragging up increases knob's value and dragging down decreases it.
        CGFloat diffY = [touch previousLocationInView:self].y - [touch locationInView:self].y;
        CGFloat diff = (fabsf(diffX) >= fabsf(diffY) ? diffX : diffY);
        
        if (diff > 0.f) {
            _dragCounter += _dragSensitivity;
            if (_dragCounter >= 1.f) {
                self.value += _dragIncrement;
                _dragCounter -= 1.f;
            }
        } else if (diff < 0.f) {
            _dragCounter -= _dragSensitivity;
            if (_dragCounter <= -1.f) {
                self.value -= _dragIncrement;
                _dragCounter += 1.f;
            }
        }
        
        _isDragging = YES;
        _tapped = NO;
		[self cf_drawImmediateCorona];
        [self cf_updateCoronaStringForValue];
    }
    
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] firstObject];
    if (touch == nil) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    
    CGPoint touchPoint = [touch locationInView:self];
    
    if ([self pointInside:touchPoint withEvent:event] && !_isDragging) {
		if (self.value < 1.f) {
			self.value += _tapIncrement;
			[self cf_drawAnimateCorona];
            [self cf_updateCoronaStringForValue];
		}
        
        _dragCounter = 0.f;
    }
    
    _tapped = (_isDragging ? NO : YES);
    _isDragging = NO;
	
	_highlightLayer.hidden = YES;
	[_highlightLayer setNeedsDisplay];
    
    [super touchesEnded:touches withEvent:event];
}

#pragma mark - Private methods

- (void)cf_updateCoronaStringForValue
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(coronaKnob:stringForValue:)]) {
        _valueLabel.text = [self.delegate coronaKnob:self stringForValue:self.value];
    } else {
        _valueLabel.text = [NSString stringWithFormat:@"%1.2f", self.value];
    }
}

- (void)cf_updateCoronaColorForValue
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(coronaKnob:coronaColorForValue:)]) {
        self.coronaColor = [self.delegate coronaKnob:self coronaColorForValue:self.value];
        _valueLabel.textColor = self.coronaColor;
    }
}

- (void)cf_drawImmediateCorona
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _coronaLayer.strokeEnd = _value;
    [CATransaction commit];
    
	[_coronaLayer setNeedsDisplay];
	_prevValue = _value;
}

- (void)cf_drawAnimateCorona
{
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
    
    // NOTE: Removing an animation that may currently be running from a previous tap
    // ensures correct animation. E.g. when the value is 0 (and the start/end anges are the same),
    // the animation would otherwise be interpolated in reverse to reach the current value
    // set for this tap.
    if ([_coronaLayer animationForKey:CORONA_ANIMATION_KEY])
        [_coronaLayer removeAnimationForKey:CORONA_ANIMATION_KEY];
    _coronaLayer.strokeEnd = _value;
	
    CAAnimationGroup *coronaAnimation = [CAAnimationGroup animation];
    CABasicAnimation *strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    strokeAnimation.duration = CORONA_ANIMATION_DURATION;
    strokeAnimation.toValue = @(strokeTarget);
    strokeAnimation.fillMode = kCAFillModeForwards;
    strokeAnimation.beginTime = 0.0;
    
    if (valueIsZero) {
        strokeAnimation.duration *= 2;
        CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnimation.duration = strokeAnimation.duration;
        fadeAnimation.toValue = @(0.0);
        fadeAnimation.fillMode = kCAFillModeForwards;
        fadeAnimation.beginTime = 0.0;
        
        coronaAnimation.animations = @[strokeAnimation, fadeAnimation];
        coronaAnimation.duration = strokeAnimation.duration + fadeAnimation.duration;
    } else if (valueWrapped) {
        strokeAnimation.duration /= 2.f;
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
	_prevValue = _value;
}

@end
