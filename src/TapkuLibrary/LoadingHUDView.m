//
//  LoadingHUDView.m
//  Created by Devin Ross on 7/2/09.
//
/*

   tapku.com || http://github.com/devinross/tapkulibrary

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation
   files (the "Software"), to deal in the Software without
   restriction, including without limitation the rights to use,
   copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following
   conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.

 */
#import "LoadingHUDView.h"
#import "NSStringAdditions.h"
#import "UIViewAdditions.h"

#define WIDTH_MARGIN  20
#define HEIGHT_MARGIN 20

@interface LoadingHUDView ()

@property (nonatomic, retain) UIProgressView *progressView;

- (CGSize)calculateHeightOfTextFromWidth:(NSString *)text font:(UIFont *)withFont width:(float)width linebreak:(UILineBreakMode)lineBreakMode;

@end

@implementation LoadingHUDView

@synthesize radius;
@synthesize progressView = _progressView;

- (id)initWithTitle:(NSString *)ttl message:(NSString *)msg
{
    if (self = [super initWithFrame:CGRectMake(0, 0, 280, 200)]) {
        _title = [ttl copy];
        _message = [msg copy];
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:_activity];
        _hidden = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (id)initWithTitle:(NSString *)ttl
{
    self = [self initWithTitle:ttl message:nil];
    if (!self) {
        return nil;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
//	if(_hidden) return;
    int width, rWidth, rHeight, x;

    UIFont *titleFont = [UIFont boldSystemFontOfSize:18];
    UIFont *messageFont = [UIFont systemFontOfSize:14];

    CGSize s1 = [self calculateHeightOfTextFromWidth:_title font:titleFont width:200 linebreak:UILineBreakModeTailTruncation];
    CGSize s2 = [self calculateHeightOfTextFromWidth:_message font:messageFont width:200 linebreak:UILineBreakModeWordWrap];

    if ([_title length] < 1) {
        s1.height = 0;
    }
    if ([_message length] < 1) {
        s2.height = 0;
    }

    CGFloat progressHeight = _activity.frame.size.height;
    if ([_activity superview] == nil) {
        progressHeight = self.progressView.frame.size.height;
    }

    if (_hidden) {
        rHeight = (5 + s1.height + s2.height + (HEIGHT_MARGIN * 2));
    } else {
        rHeight = (10 + s1.height + s2.height + (HEIGHT_MARGIN * 2) + 10 + progressHeight);
    }

    rWidth = width = (s2.width > s1.width) ? (int)s2.width : (int)s1.width;
    rWidth += WIDTH_MARGIN * 2;
    x = (280 - rWidth) / 2;

    _activity.center = CGPointMake(280 / 2, HEIGHT_MARGIN + _activity.frame.size.height / 2);
    self.progressView.center = CGPointMake(280 / 2, HEIGHT_MARGIN + self.progressView.frame.size.height / 2);

    // NSLog(@"DRAW RECT %d %f",rHeight,self.frame.size.height);

    // DRAW ROUNDED RECTANGLE
    [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.9] set];
    CGRect r = CGRectMake(x, 0, rWidth, rHeight);
    [UIView drawRoundRectangleInRect:r
                          withRadius:10.0
                               color:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.75]];

    // DRAW FIRST TEXT
    [[UIColor whiteColor] set];
    if (_hidden) {
        r = CGRectMake(x + WIDTH_MARGIN, HEIGHT_MARGIN, width, s1.height);
    } else {
        r = CGRectMake(x + WIDTH_MARGIN, 5 + progressHeight + HEIGHT_MARGIN, width, s1.height);
    }
    CGSize s = [_title drawInRect:r withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];

    // DRAW SECOND TEXT
    r.origin.y += s.height + 5;
    r.size.height = s2.height;
    [_message drawInRect:r withFont:messageFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
}

- (void)setProgress:(NSNumber *)progressNumber outOfTotal:(NSNumber *)totalNumber
{
    if (progressNumber == nil || totalNumber == nil) {
        if (self.progressView.superview != nil) {
            [self addSubview:_activity];
            [self.progressView removeFromSuperview];
        }
    } else {
        if ([_activity superview] != nil) {
            [_activity removeFromSuperview];
            [self addSubview:self.progressView];
        }

        [self.progressView setProgress:([progressNumber floatValue] / [totalNumber floatValue]) animated:YES];
    }
}

- (void)setTitle:(NSString *)str
{
    [_title release];
    _title = [str copy];
    // [self updateHeight];
    [self setNeedsDisplay];
}
- (NSString *)title
{
    return _title;
}

- (void)setMessage:(NSString *)str
{
    [_message release];
    _message = [str copy];
    [self setNeedsDisplay];
}
- (NSString *)message
{
    return _message;
}

- (void)setRadius:(float)f
{
    if (f == radius) {
        return;
    }

    radius = f;
    [self setNeedsDisplay];
}

- (void)startAnimating
{
    if (!_hidden) {
        return;
    }
    _hidden = NO;
    [self setNeedsDisplay];
    [_activity startAnimating];
}
- (void)stopAnimating
{
    if (_hidden) {
        return;
    }
    _hidden = YES;
    [self setNeedsDisplay];
    [_activity stopAnimating];
}

- (CGSize)calculateHeightOfTextFromWidth:(NSString *)text font:(UIFont *)withFont width:(float)width linebreak:(UILineBreakMode)lineBreakMode
{
    return [text sizeWithFont:withFont
            constrainedToSize:CGSizeMake(width, FLT_MAX)
                lineBreakMode:lineBreakMode];
}
- (void)adjustHeight
{
    CGSize s1 = [_title heightWithFont:[UIFont boldSystemFontOfSize:16.0]
                                 width:200.0
                             linebreak:UILineBreakModeTailTruncation];

    CGSize s2 = [_message heightWithFont:[UIFont systemFontOfSize:12.0]
                                   width:200.0
                               linebreak:UILineBreakModeCharacterWrap];

    CGRect r = self.frame;
    r.size.height = s1.height + s2.height + 20;
    self.frame = r;
}

- (void)dealloc
{
    [_activity release];
    [_title release];
    [_message release];
    [_progressView release], _progressView = nil;
    [super dealloc];
}

- (UIProgressView *)progressView
{
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    }

    return _progressView;
}

@end