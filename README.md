# FSCoronaKnob

## Corona Knob Control for iOS
This knob is a circular control with a colored corona that represents its value. It supports both tap and drag gestures to change its value. An optional delegate object allows for customized labels to display the value in the middle of the knob as well as setting the corona's color dynamically. 

![](knob_exs.png "Knobs")

Requires iOS SDK 7.0+ and ARC. 

## Installation
Simply download this repository and copy _FSCoronaKnob.h_ & _FSCoronaKnob.m_ into your project.

## Usage
Initialize a corona knob with a size and a delegate if desired:
```
id<FSCoronaKnobDelegate> aDelegate = ...
FSCoronaKnob *knob = [[FSCoronaKnob alloc] initWithSize:CGSizeMake(56.0, 56.0) delegate:aDelegate];
```
Customize behavior and appearance of the knob:
```
knob.startAngle = 3.0 * M_PI / 4.0;
knob.endAngle = M_PI / 4.0;
knob.knobWidth = 1.5;
knob.coronaWidth = 3.0;
knob.valueWrapping = FSCoronaKnobValueWrapNone;
knob.knobBackgroundColor = [UIColor lightGrayColor];
knob.dragIncrement = 0.02;
knob.tapIncrement = 0.5;
knob.valueWrapping = FSCoronaKnobValueWrapPositive | FSCoronaKnobValueWrapNegative;
```
Observe changes to the knob's value via a target & selector, or by suppling a block:
```
[knob addTarget:self action:@selector(__knobValueChanged:) forControlEvents:UIControlEventValueChanged];

knob.onValueChanged = ^void(FSCoronaKnob *knob) {
    // ...
};
```
Customize the knob's value label text and/or the corona's color by implementing the `FSCoronaKnobDelegate` protocol:
```
- (NSString *)coronaKnob:(FSCoronaKnob *)knob stringForValue:(CGFloat)value {
    if (value == 0.0 || value == 1.0) {
        return @":00";
    } else if (value == 0.25) {
        return @":15";
    } else if (value == 0.5) {
        return @":30";
    } else {
        return @":45";
    }

    return @"";
}

- (UIColor *)coronaKnob:(FSCoronaKnob *)knob coronaColorForValue:(CGFloat)value {
    UIColor *color = [UIColor colorWithRed:0.f green:value blue:value alpha:1.f];
    return color;
}
```

---

Copyright (C) 2014  Flyingsand

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
