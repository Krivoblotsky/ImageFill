//
//  ColorableImageView.m
//  color
//
//  Created by Onix on 3/30/13.
//  Copyright (c) 2013 Onix. All rights reserved.
//

#import "ColorableImageView.h"
#import <QuartzCore/QuartzCore.h>

@interface ColorableImageView()
@property (nonatomic) CGPoint pointTouched;
@property (nonatomic) BOOL imageHasBeenDrawn;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIColor *color;
@end

@implementation ColorableImageView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.pointTouched = [touch locationInView:self];
    self.image = [self imageForView:self];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!self.imageHasBeenDrawn) {
        UIImage* image = [UIImage imageNamed:@"raskraska-spanch-boba"];
        [image drawInRect:rect];
        self.imageHasBeenDrawn = YES;
    } else {
        CGImageRef imageRef = [self.image CGImage];
        
        NSUInteger width = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        CGContextRef offscreenContext = CGBitmapContextCreate(rawData, width, height,
                                                              bitsPerComponent, bytesPerRow, colorSpace,
                                                              kCGImageAlphaPremultipliedLast |
                                                              kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGPoint point = CGPointMake(self.pointTouched.x * scale, self.pointTouched.y * scale);
        CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), imageRef);
        
        self.color = [UIColor colorWithRed:0.3 green:0.5 blue:0.7 alpha:1];
        [self floodFillInContext:offscreenContext
                         atPoint:point
                       withColor:self.color
                   originalImage:imageRef
                         rawData:rawData];
        
        CGImageRef resultImage = CGBitmapContextCreateImage(offscreenContext);
        CGContextRelease(offscreenContext);
        
        UIImage *image = [UIImage imageWithCGImage:resultImage];
        [image drawInRect:rect];
        free(rawData);
    }
}

- (UIImage *)imageForView:(UIView *)view {
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, scale);
    [view.layer renderInContext: UIGraphicsGetCurrentContext()];
    UIImage *retval = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return retval;
}

- (void)floodFillInContext:(CGContextRef)context
                   atPoint:(CGPoint)point
                 withColor:(UIColor *)color
             originalImage:(CGImageRef)image
                   rawData:(unsigned char*)rawData {
    
    NSUInteger width = CGImageGetWidth(image);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    
    int byteIndex = (bytesPerRow * point.y) + point.x * bytesPerPixel;
    
    if (byteIndex > 0) {
        CGFloat currentRed   = rawData[byteIndex];
        CGFloat currentGreen = rawData[byteIndex + 1];
        CGFloat currentBlue  = rawData[byteIndex + 2];

        const CGFloat* components = CGColorGetComponents(color.CGColor);
        CGFloat newRed = components[0] * 255;
        CGFloat newGreen = components[1] * 255;
        CGFloat newBlue = components[2] * 255;
        
        if (currentRed != newRed && currentGreen != newGreen && currentBlue != newBlue) {
            if (currentBlue == 255 && currentBlue == 255 && currentGreen == 255) {
                
                rawData[byteIndex] = (char) (newRed);
                rawData[byteIndex + 1] = (char) (newGreen);
                rawData[byteIndex + 2] = (char)(newBlue);
                rawData[byteIndex + 3] = (char)(255);
                
                if (point.y - 1 >= 0) {
                    [self floodFillInContext:context atPoint:CGPointMake(point.x, point.y - 1) withColor:color originalImage:image rawData:rawData];
                }
                
                if (point.x + 1 <= width) {
                    [self floodFillInContext:context atPoint:CGPointMake(point.x + 1, point.y) withColor:color originalImage:image rawData:rawData];
                }
                
                if (point.y + 1 <= CGImageGetWidth(image)) {
                    [self floodFillInContext:context atPoint:CGPointMake(point.x, point.y + 1) withColor:color originalImage:image rawData:rawData];
                }
                
                if (point.x - 1 >= 0) {
                    [self floodFillInContext:context atPoint:CGPointMake(point.x - 1, point.y) withColor:color originalImage:image rawData:rawData];
                }
            } else {
                rawData[byteIndex] = (char) (newRed);
                rawData[byteIndex + 1] = (char) (newGreen);
                rawData[byteIndex + 2] = (char)(newBlue);
                rawData[byteIndex + 3] = (char)(200);
            }
        }
    }
}

@end
