//
//  ViewController.m
//  ImageFill
//
//  Created by Onix on 4/1/13.
//  Copyright (c) 2013 Onix. All rights reserved.
//

#import "ViewController.h"
#import "ColorableImageView.h"
#import "FCColorPickerViewController.h"

@interface ViewController () <ColorPickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet ColorableImageView *colorableImageView;
@end

@implementation ViewController

- (IBAction)pickColorButtonAction:(id)sender {
    FCColorPickerViewController *controller = [[FCColorPickerViewController alloc] init];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)colorPickerViewController:(FCColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
    self.colorView.backgroundColor = color;
    self.colorableImageView.color = color;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorPickerViewControllerDidCancel:(FCColorPickerViewController *)colorPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end