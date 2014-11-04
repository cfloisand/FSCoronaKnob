//
//  CFViewController.h
//  CFCoronaKnob
//
//  Created by Christian on 2014-06-30.
//  Copyright (c) 2014 Rainland. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFCoronaKnob/CFCoronaKnob.h"


@interface CFViewController : UIViewController <CFCoronaKnobDelegate>

@property (nonatomic, strong) CFCoronaKnob *coronaKnob1;
@property (nonatomic, strong) CFCoronaKnob *coronaKnob2;
@property (nonatomic, strong) CFCoronaKnob *coronaKnob3;

@end
