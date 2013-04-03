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

typedef struct {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
} Color;

@interface ColorableImageView()
@property (nonatomic) CGPoint pointTouched;
@property (nonatomic) BOOL imageHasBeenDrawn;
@property (nonatomic, strong) UIImage *image;
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
        
        self.counter = 0;
        
        [self floodFillInContext:offscreenContext
                         atPoint:point
                       withColor:self.color
                   originalImage:imageRef
                         rawData:rawData direction:0];
                
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
    Color newColor = {floorf(components[0] * 255), floor(components[1] * 255), floor(components[2] * 255)};
    Color oldColor = [self colorAtPoint:point bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel inData:rawData];
    if (colorEqualsColor(oldColor, newColor, NO)) {
        return;
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    //Add CGpoint
    SKPoint *pointObject = [[SKPoint alloc] init];
    pointObject.x = point.x;
    pointObject.y = point.y;
    [array addObject:pointObject];
    
    BOOL spanLeft = 0;
    BOOL spanRight = 0;
    
    while (array.count) {
        SKPoint *currentPoint = [array lastObject];
        [array removeLastObject];
        
        CGFloat y1 = currentPoint.y;
        while (y1 >= 0 &&
               colorEqualsColor([self colorAtPoint:CGPointMake(currentPoint.x, y1)
                                       bytesPerRow:bytesPerRow
                                     bytesPerPixel:bytesPerPixel inData:rawData],oldColor,NO)) {
            y1--;
        }
        
        y1++;
        spanLeft = spanRight = 0;
        
        while (y1 < CGImageGetHeight(image) &&
               colorEqualsColor([self colorAtPoint:CGPointMake(currentPoint.x,y1)
                                       bytesPerRow:bytesPerRow bytesPerPixel:bytesPerPixel
                                            inData:rawData], oldColor, NO)) {
            
            
            int byteIndex = (bytesPerRow * y1) + currentPoint.x * bytesPerPixel;
            rawData[byteIndex] = (char) (newColor.red);
            rawData[byteIndex + 1] = (char) (newColor.green);
            rawData[byteIndex + 2] = (char)(newColor.blue);
            rawData[byteIndex + 3] = (char)(255);
            
            if (!spanLeft &&
                currentPoint.x > 0 &&
                colorEqualsColor([self colorAtPoint:CGPointMake(currentPoint.x - 1, y1)
                                        bytesPerRow:bytesPerRow
                                      bytesPerPixel:bytesPerPixel
                                             inData:rawData], oldColor, NO)) {
                SKPoint *newPoint = [[SKPoint alloc] init];
                newPoint.x = currentPoint.x - 1;
                newPoint.y = y1;
                [array addObject:newPoint];
                spanLeft = YES;
            } else if (spanLeft &&
                       currentPoint.x > 0 &&
                       !colorEqualsColor([self colorAtPoint:CGPointMake(currentPoint.x - 1, y1)
                                                bytesPerRow:bytesPerRow
                                              bytesPerPixel:bytesPerPixel
                                                     inData:rawData], oldColor, NO)) {
                spanLeft = NO;
            } else if (!spanRight &&
                       currentPoint.x < width - 1 &&
                       colorEqualsColor([self colorAtPoint:CGPointMake(currentPoint.x + 1, y1)
                                               bytesPerRow:bytesPerRow
                                             bytesPerPixel:bytesPerPixel
                                                    inData:rawData], oldColor, NO)) {
                SKPoint *newPoint = [[SKPoint alloc] init];
                newPoint.x = currentPoint.x + 1;
                newPoint.y = y1;
                [array addObject:newPoint];
                spanRight = YES;
            } else if (spanRight &&
                       currentPoint.x < width - 1 &&
                       !colorEqualsColor([self colorAtPoint:CGPointMake(currentPoint.x + 1, y1)
                                               bytesPerRow:bytesPerRow
                                              bytesPerPixel:bytesPerPixel
                                                    inData:rawData], oldColor, NO)) {
                spanRight = NO;
            }
            
            y1++;
        };
        
    }
}

- (Color)colorAtPoint:(CGPoint)point
          bytesPerRow:(NSUInteger)bytesPerRow
        bytesPerPixel:(NSUInteger)bytesPerPixel
               inData:(unsigned char*)rawData {
    int byteIndex = (bytesPerRow * point.y) + point.x * bytesPerPixel;
    Color color = {rawData[byteIndex], rawData[byteIndex + 1], rawData[byteIndex + 2],rawData[byteIndex + 3]};
    return color;
}

- (Color)colorAtByteIndex:(NSUInteger)byteIndex inRawData:(unsigned char *)rawData {
    Color color = {rawData[byteIndex], rawData[byteIndex + 1], rawData[byteIndex + 2],rawData[byteIndex + 3]};
    return color;
}

BOOL colorEqualsColor(Color color1, Color color2, BOOL countAlpha) {
    if (countAlpha && color1.alpha != color2.alpha) {
        return NO;
    }
    return (color1.red == color2.red && color1.green == color2.green && color1.blue == color2.blue);
}
@end
