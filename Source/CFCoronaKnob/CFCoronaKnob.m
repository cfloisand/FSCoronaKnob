//
//  File:		CFCoronaKnob.m
//  Author:		Christian Floisand
//	Created:	2014-06-30
//	Modified:	2014-11-09
//

#import <QuartzCore/QuartzCore.h>
#import "CFCoronaKnob.h"

#define TWOPI (6.2831853071795865)
#define THREEPI_OVER2 (4.71238898038469)
#define ANGLE_DIFF_OFFSET (0.00001f)
#define CORONA_ANIMATION_DURATION (0.24f)
#define HIGHLIGHT_LAYER_OPACITY (0.52f)

#define DEFAULT_START_ANGLE		THREEPI_OVER2
#define DEFAULT_END_ANGLE		THREEPI_OVER2
#define DEFAULT_VALUE			0.f
#define DEFAULT_TAP_INCREMENT	0.25f
#define DEFAULT_DRAG_INCREMENT  0.01f
#define DEFAULT_DRAG_SENSITIVITY 1.f
#define DEFAULT_KNOB_COLOR      [UIColor colorWithRed:221.f/255.f green:225.f/255.f blue:220.f/255.f alpha:1.f]
#define DEFAULT_CORONA_COLOR    [UIColor colorWithRed:141.f/255.f green:196.f/255.f blue:223.f/255.f alpha:1.f]
#define DEFAULT_BACKGROUND_COLOR [UIColor clearColor]
#define DEFAULT_KNOB_WIDTH		4.f
#define DEFAULT_CORONA_WIDTH    4.f


// TODO: Floating-point equality needs to use approximation.

@interface CFCoronaKnob ()
{
    CGPoint _centerPoint;
	CGFloat _prevValue;
	CGFloat _angleDiff;
    CGFloat _radius;
    
    BOOL _isDragging;
    CGFloat _dragCounter;
}
@property (nonatomic, copy) CGFloat (^calcRadius)(void);
@property (nonatomic, copy) CGFloat (^calcStartEndAngleDiff)(void);
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
		_angleDiff = TWOPI - ANGLE_DIFF_OFFSET;
        _value = DEFAULT_VALUE;
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
        
        _calcRadius = ^CGFloat (void) {
            typeof(self) strongSelf = weakSelf;
            return strongSelf.bounds.size.width / 2.f - strongSelf->_coronaWidth;
        };
        
        _calcStartEndAngleDiff = ^CGFloat (void) {
            typeof(self) strongSelf = weakSelf;
            if (fabsf(strongSelf.endAngle - strongSelf.startAngle) < FLT_MIN) {
                // Subtract small value to prevent corona wrapping when startAngle and endAngle are the same.
                return (TWOPI - ANGLE_DIFF_OFFSET);
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
    _centerPoint = [self.superview convertPoint:self.center toView:self];
    
    // Setup just the background and knob layers for now, and leave the corona and highlight layers until they are needed.
    
    CAShapeLayer *backLayer = [CAShapeLayer layer];
    // Inset the background layer to make sure it doesn't spill out beyond the knob.
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
    knobLayer.path = [[UIBezierPath bezierPathWithArcCenter:_centerPoint radius:_radius startAngle:0.f endAngle:TWOPI clockwise:YES] CGPath];
    [self.layer addSublayer:knobLayer];
    _knobLayer = knobLayer;
    
    // Add the value label as subview last so it appears over the top of the other layers.
    
    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.font = [UIFont systemFontOfSize:11.f];
    valueLabel.textColor = self.coronaColor;
    valueLabel.textAlignment = NSTextAlignmentCenter;
    valueLabel.frame = self.bounds;
    [self addSubview:valueLabel];
    _valueLabel = valueLabel;
    
    [self cf_updateCoronaStringForValue];
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
	_angleDiff = self.calcStartEndAngleDiff();
}

- (void)setEndAngle:(CGFloat)endAngle
{
	_endAngle = endAngle;
	_angleDiff = self.calcStartEndAngleDiff();
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
    _radius = self.calcRadius();
}

- (void)setBounds:(CGRect)bounds
{
    NSAssert(bounds.size.width == bounds.size.height, @"Corona Knob's width and height must be the same.");
    super.bounds = bounds;
    _radius = self.calcRadius();
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    // Disallow setting the view's background color.
    super.backgroundColor = [UIColor clearColor];
}

- (void)setOpaque:(BOOL)opaque
{
    // Allowing the opaque property to be YES would mess up drawing of the control.
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
    
    if ([self pointInside:touchPoint withEvent:event] && ! _isDragging) {
        // Increment if touch up was inside the label's bounds and was not the end of a touches moved phase.
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

// Returns the bezier path for the corona based on the current value.
- (UIBezierPath *)cf_coronaPathWithOffset:(CGFloat)offset
{
	CGFloat valueAngle = (_startAngle + _value * _angleDiff) - offset;
	valueAngle = (valueAngle > TWOPI ? valueAngle-TWOPI : valueAngle);
		
	return [UIBezierPath bezierPathWithArcCenter:_centerPoint
										  radius:_radius
									  startAngle:_startAngle
										endAngle:valueAngle
									   clockwise:YES];
}

// For drawing the corona immediately with no animation. This method is used when the user is dragging to change
// the knob's value.
- (void)cf_drawImmediateCorona
{
	if ( ! _coronaLayer ) {
		[self cf_initCoronaLayer];
	}
	
	_coronaLayer.path = [[self cf_coronaPathWithOffset:0.f] CGPath];
	[_coronaLayer setNeedsDisplay];
	
	_prevValue = _value;
}

// For drawing the corona using animation when the user taps the knob. The corona animates from the current value to
// the target value along the path.
- (void)cf_drawAnimateCorona
{
	if ( ! _coronaLayer ) {
		[self cf_initCoronaLayer];
	}
	
    UIBezierPath *animatedPath;
    UIBezierPath *completedPath = nil;
    CGFloat fromValue;
    
    if (_value == 0.f) {
        // When the knob's value is 0.0, the corona path should still visually complete its animation before disappearing.
        // The path returned needs to be offset by a small amount so it will still be drawn, but the actual path corresponding to the
        // value of 0.0 is saved as |completedPath| and set to the layer after the animation is completed.
        animatedPath = [self cf_coronaPathWithOffset:ANGLE_DIFF_OFFSET];
        completedPath = [self cf_coronaPathWithOffset:0.f];
        fromValue = _prevValue;
    } else {
        animatedPath = [self cf_coronaPathWithOffset:0.f];
        
        // To prevent the corona path from snapping back during animation if the current value is less than |_tapIncrement| amount
        // away from the maximum value of 1.0.
        if (_value > (1.f - _tapIncrement) && _value <= 1.f) {
            fromValue = _prevValue;
        } else {
            fromValue = _value;
        }
    }
    
    _coronaLayer.path = animatedPath.CGPath;
	
    CAAnimationGroup *coronaAnimation = [CAAnimationGroup animation];
    CABasicAnimation *strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    strokeAnimation.duration = CORONA_ANIMATION_DURATION;
    strokeAnimation.fromValue = @(fromValue);
    strokeAnimation.toValue = @(1.0);
    strokeAnimation.fillMode = kCAFillModeForwards;
    strokeAnimation.beginTime = 0.0;
    
    if (completedPath) {
        CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeAnimation.duration = 0.160;
        fadeAnimation.fromValue = @(1.0);
        fadeAnimation.toValue = @(0.0);
        fadeAnimation.fillMode = kCAFillModeForwards;
        fadeAnimation.beginTime = strokeAnimation.beginTime + strokeAnimation.duration;
        
        coronaAnimation.animations = @[strokeAnimation, fadeAnimation];
        coronaAnimation.duration = strokeAnimation.duration + fadeAnimation.duration;
        
        // Wait until the animation group has completed before setting the corona to its actual path. Setting the completed path
        // in the completion block of a UIView animation block does not work.
        // FIXME: User interaction is turned off temporarily so that the following block does not overwrite a new value/path with the
        // completed path from the previous touch interaction. But it's preferred not to block actions, even for a very short time.
        self.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((coronaAnimation.duration-0.04) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _coronaLayer.path = completedPath.CGPath;
            self.userInteractionEnabled = YES;
        });
    } else {
        coronaAnimation.animations = @[strokeAnimation];
        coronaAnimation.duration = strokeAnimation.duration;
    }
    
    [_coronaLayer addAnimation:coronaAnimation forKey:@"coronaAnimation"];
    
	_prevValue = _value;
}

- (void)cf_initCoronaLayer
{
	CAShapeLayer *coronaLayer = [CAShapeLayer layer];
	coronaLayer.frame = self.bounds;
	coronaLayer.strokeColor = self.coronaColor.CGColor;
	coronaLayer.fillColor = nil;
    coronaLayer.opacity = 1.f;
    coronaLayer.zPosition = 2.f;
	coronaLayer.lineWidth = self.coronaWidth;
	coronaLayer.lineJoin = kCALineJoinMiter;
    [self.layer addSublayer:coronaLayer];
	_coronaLayer = coronaLayer;
}

@end
