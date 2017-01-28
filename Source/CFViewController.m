//
//  CFViewController.m
//  CFCoronaKnob
//
//  Created by Christian on 2014-06-30.
//  Copyright (c) 2014 Rainland. All rights reserved.
//

#import "CFViewController.h"

#define Rad2Deg	(57.29577951308232)
#define Deg2Rad (0.0174532925199433)


@interface CFViewController ()

@end

@implementation CFViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.coronaKnob1 = [[CFCoronaKnob alloc] initWithFrame:CGRectMake(20.f, 50.f, 44.f, 44.f)];
    self.coronaKnob1.valueWrapping = CFCoronaKnobValueWrapPositive | CFCoronaKnobValueWrapNegative;
    //self.coronaKnob1.tapIncrement = 0.15f;
    [self.coronaKnob1 addTarget:self action:@selector(knobTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.coronaKnob1];
    
    self.coronaKnob2 = [[CFCoronaKnob alloc] initWithFrame:CGRectMake(74.f, 50.f, 44.f, 44.f)];
    self.coronaKnob2.startAngle = 3.f * M_PI / 4.f;
    self.coronaKnob2.endAngle = M_PI / 4.f;
    self.coronaKnob2.knobWidth = 1.5f;
    self.coronaKnob2.coronaWidth = 3.f;
    self.coronaKnob2.valueWrapping = CFCoronaKnobValueWrapNone;
    self.coronaKnob2.knobBackgroundColor = [UIColor colorWithRed:0.f green:146.f/255.f blue:210.f/255.f alpha:0.1f];
    [self.coronaKnob2 addTarget:self action:@selector(knobTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.coronaKnob2];
    
    self.coronaKnob3 = [[CFCoronaKnob alloc] initWithFrame:CGRectMake(138.f, 50.f, 56.f, 56.f) delegate:self];
    self.coronaKnob3.knobWidth = 4.f;
    self.coronaKnob3.coronaWidth = 1.5f;
    self.coronaKnob3.dragIncrement = 0.f;
    self.coronaKnob3.valueWrapping = CFCoronaKnobValueWrapPositive;
    self.coronaKnob3.knobBackgroundColor = [UIColor colorWithWhite:0.17f alpha:0.08f];
    [self.coronaKnob3 addTarget:self action:@selector(knobTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.coronaKnob3];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)knobTouch:(id)sender {
    //NSLog(@"knob touched");
}

#pragma mark - CFCoronaKnobDelegate

- (NSString *)coronaKnob:(CFCoronaKnob *)knob stringForValue:(CGFloat)value {
    if (knob == self.coronaKnob3 && knob.tapped) {
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

- (UIColor *)coronaKnob:(CFCoronaKnob *)knob coronaColorForValue:(CGFloat)value {
	UIColor *color = [UIColor colorWithRed:0.f green:value blue:value alpha:1.f];
	return color;
}

@end
