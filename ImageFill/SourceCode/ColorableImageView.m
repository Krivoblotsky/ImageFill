//
//  ColorableImageView.m
//  color
//
//  Created by Onix on 3/30/13.
//  Copyright (c) 2013 Onix. All rights reserved.
//

#import "ColorableImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "SKPoint.h"

@interface ColorableImageView()
@property (nonatomic) CGPoint pointTouched;
@property (nonatomic) BOOL imageHasBeenDrawn;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic) NSInteger counter;
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
        
        self.counter = 0;
        
        NSLog(@"Start");
        [self floodFillInContext:offscreenContext
                         atPoint:point
                       withColor:self.color
                   originalImage:imageRef
                         rawData:rawData direction:0];
        
        NSLog(@"End");
        
        CGImageRef resultImage = CGBitmapContextCreateImage(offscreenContext);
        CGContextRelease(offscreenContext);
        
        UIImage *image = [UIImage imageWithCGImage:resultImage];
        [image drawInRect:rect];
        free(rawData);
        CGImageRelease(resultImage);
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
                   rawData:(unsigned char*)rawData
                 direction:(NSInteger)direction {
    
    self.counter ++;
    NSUInteger width = CGImageGetWidth(image);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    
    const CGFloat* components = CGColorGetComponents(color.CGColor);
    CGFloat newRed = components[0] * 255;
    CGFloat newGreen = components[1] * 255;
    CGFloat newBlue = components[2] * 255;
    
    NSMutableArray *array = [[NSMutableArray alloc] init];

    //Add CGpoint
    SKPoint *pointObject = [[SKPoint alloc] init];
    pointObject.x = point.x;
    pointObject.y = point.y;
    [array addObject:pointObject];
    
    while (array.count) {        
        
        SKPoint *currentPoint = [array lastObject];
        
        [array removeLastObject];
        
        if (currentPoint.x >= 0 && currentPoint.x < width && currentPoint.y >= 0 && currentPoint.y < CGImageGetHeight(image)) {
            int byteIndex = (bytesPerRow * currentPoint.y) + currentPoint.x * bytesPerPixel;
            if (byteIndex > 0) {
                    CGFloat currentRed   = rawData[byteIndex];
                    CGFloat currentGreen = rawData[byteIndex + 1];
                    CGFloat currentBlue  = rawData[byteIndex + 2];
                    
                    if (currentRed != newRed && currentGreen != newGreen && currentBlue != newBlue) {
                        if (currentBlue > 230 && currentBlue > 230 && currentGreen > 230) {
                            rawData[byteIndex] = (char) (newRed);
                            rawData[byteIndex + 1] = (char) (newGreen);
                            rawData[byteIndex + 2] = (char)(newBlue);
                            rawData[byteIndex + 3] = (char)(255);
                            
                           SKPoint *point = [[SKPoint alloc] init];
                           point.x = currentPoint.x;
                           point.y = currentPoint.y - 1;
                           [array addObject:point];
                           
                           point = [[SKPoint alloc] init];
                           point.x = currentPoint.x + 1;
                           point.y = currentPoint.y;
                           [array addObject:point];
                           
                           point = [[SKPoint alloc] init];
                           point.x = currentPoint.x;
                           point.y = currentPoint.y + 1;
                           [array addObject:point];
                                              
                            point = [[SKPoint alloc] init];
                            point.x = currentPoint.x - 1;
                            point.y = currentPoint.y;
                            [array addObject:point];
                                              
                        } else {
                            rawData[byteIndex] = (char) (newRed);
                            rawData[byteIndex + 1] = (char) (newGreen);
                            rawData[byteIndex + 2] = (char)(newBlue);
                            rawData[byteIndex + 3] = (char)(200);
                        }
                }
            }
        }
    }
}

@end
