//
//  ViewController.m
//  FSCoronaKnob
//
//  Created by Christian on 2014-06-30.
//  Copyright (c) 2014 Flyingsand. All rights reserved.
//

#import "ViewController.h"
#import "FSCoronaKnob.h"

#define KNOB3_TAG 10


@interface ViewController ()<FSCoronaKnobDelegate>

@end

@implementation ViewController {
    FSCoronaKnob * __weak _knob1;
    FSCoronaKnob * __weak _knob2;
    FSCoronaKnob * __weak _knob3;
}

- (void)loadView {
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = YES;
    v.frame = [[UIScreen mainScreen] bounds];
    v.backgroundColor = [UIColor whiteColor];
    self.view = v;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FSCoronaKnob *knob1 = [[FSCoronaKnob alloc] initWithSize:CGSizeMake(56.0, 56.0) delegate:nil];
    knob1.valueWrapping = FSCoronaKnobValueWrapPositive | FSCoronaKnobValueWrapNegative;
    //self.coronaKnob1.tapIncrement = 0.15f;
    [knob1 addTarget:self action:@selector(__knobTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:knob1];
    [knob1.leadingAnchor constraintEqualToAnchor:knob1.superview.leadingAnchor constant:20.0].active = YES;
    [knob1.centerYAnchor constraintEqualToAnchor:knob1.superview.centerYAnchor].active = YES;
    _knob1 = knob1;
    
    FSCoronaKnob *knob2 = [[FSCoronaKnob alloc] initWithSize:CGSizeMake(56.0, 56.0) delegate:nil];
    knob2.startAngle = 3.0 * M_PI / 4.0;
    knob2.endAngle = M_PI / 4.0;
    knob2.knobWidth = 1.5;
    knob2.coronaWidth = 3.0;
    knob2.valueWrapping = FSCoronaKnobValueWrapNone;
    knob2.knobBackgroundColor = [UIColor colorWithRed:0.f green:146.f/255.f blue:210.f/255.f alpha:0.1f];
    [knob2 addTarget:self action:@selector(__knobTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:knob2];
    [knob2.leadingAnchor constraintEqualToAnchor:knob1.trailingAnchor constant:40.0].active = YES;
    [knob2.centerYAnchor constraintEqualToAnchor:knob2.superview.centerYAnchor].active = YES;
    _knob2 = knob2;
    
    FSCoronaKnob *knob3 = [[FSCoronaKnob alloc] initWithSize:CGSizeMake(80.0, 80.0) delegate:self];
    knob3.tag = KNOB3_TAG;
    knob3.knobWidth = 4.0;
    knob3.coronaWidth = 1.5;
    knob3.dragIncrement = 0.0;
    knob3.valueWrapping = FSCoronaKnobValueWrapPositive;
    knob3.knobBackgroundColor = [UIColor colorWithWhite:0.17 alpha:0.08];
    knob3.valueLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:24.0];
    [knob3 addTarget:self action:@selector(__knobTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:knob3];
    [knob3.leadingAnchor constraintEqualToAnchor:knob2.trailingAnchor constant:40.0].active = YES;
    [knob3.centerYAnchor constraintEqualToAnchor:knob3.superview.centerYAnchor].active = YES;
    _knob3 = knob3;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)__knobTouch:(id)sender {
    //NSLog(@"knob touched");
}

#pragma mark - FSCoronaKnobDelegate
- (NSString *)coronaKnob:(FSCoronaKnob *)knob stringForValue:(CGFloat)value {
    if (knob.tag == KNOB3_TAG) {
        if (value == 0.f || value == 1.f) {
            return @":00";
        } else if (value == 0.25f) {
            return @":15";
        } else if (value == 0.5f) {
            return @":30";
        } else {
            return @":45";
        }
    }
    
    return @"";
}

- (UIColor *)coronaKnob:(FSCoronaKnob *)knob coronaColorForValue:(CGFloat)value {
    if (knob.tag == KNOB3_TAG) {
        UIColor *color = [UIColor colorWithRed:0.f green:value blue:value alpha:1.f];
        return color;
    } else {
        return nil;
    }
}

@end
