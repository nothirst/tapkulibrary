//
//  TKCalendarView.m
//  Created by Devin Ross on 7/28/09.
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

#import "TKUCalendarMonthView.h"

#import "NSDate+TKUAdditions.h"
#import "UIImage+TKUAdditions.h"
#import "UIView+TKUAdditions.h"

@class TKUCalendarDayView;

@interface TKUMonthGridView : UIView

@property (unsafe_unretained, nonatomic) id delegate;
@property TKUCalendarDayView *selectedDayView;
@property NSInteger numberOfLines;
@property NSInteger todaysDay;
@property NSInteger weekdayOfFirst;
@property NSDate *dateOfFirst;
@property (nonatomic, strong) NSArray *marks;
@property NSMutableArray *dayTiles;
@property NSMutableArray *reusableDayViews;

- (id)initWithStartDate:(NSDate *)theDate today:(NSInteger)todayDay marks:(NSArray *)marksArray;
- (void)selectDay:(int)theDayNumber;
- (void)resetMarks;
- (void)setStartDate:(NSDate *)theDate today:(NSInteger)todayDay marks:(NSArray *)marksArray;
- (void)buildGrid;

@end

@interface TKUCalendarDayView : UIView

@property (copy, nonatomic) NSString *dayText;
@property (assign, nonatomic, getter = isSelected) BOOL selected;
@property (assign, nonatomic, getter = isActive) BOOL active;
@property (assign, nonatomic, getter = isToday) BOOL today;
@property (assign, nonatomic, getter = isMarked) BOOL marked;

- (id)initWithFrame:(CGRect)frame string:(NSString *)string selected:(BOOL)sel active:(BOOL)act today:(BOOL)tdy marked:(BOOL)mark;
- (void)setString:(NSString *)string selected:(BOOL)sel active:(BOOL)act today:(BOOL)tdy marked:(BOOL)mark;

@end

@interface TKUCalendarMonthView ()

@property UIButton *leftButton;
@property UIButton *rightButton;
@property UIScrollView *scrollView;
@property NSDate *currentMonthDate;
@property UIImageView *shadowImageView;
@property NSMutableArray *deck;
@property NSDate *selectedMonthDate;
@property NSString *monthYearString;

@end

@implementation TKUCalendarMonthView

- (void)loadButtons
{
    self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.leftButton addTarget:self action:@selector(leftButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.leftButton setImage:[UIImage imageNamed:@"leftarrow"] forState:0];
    [self addSubview:self.leftButton];
    self.leftButton.frame = CGRectMake(0.0, 0.0, 44.0, 36.0);

    self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rightButton setImage:[UIImage imageNamed:@"rightarrow"] forState:0];
    [self.rightButton addTarget:self action:@selector(rightButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.rightButton];
    self.rightButton.frame = CGRectMake(320.0 - 44.0, 0.0, 44.0, 36.0);
}

- (void)loadInitialGrids
{
    NSArray *marks = [self getMarksDataWithDate:self.currentMonthDate];

    TKUMonthGridView *currentMonthGridView = [[TKUMonthGridView alloc] initWithStartDate:self.currentMonthDate today:[[NSDate date] dateInformation].day marks:marks];
    [currentMonthGridView setDelegate:self];
    
    UISwipeGestureRecognizer *leftToRightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToRecedeMonth:)];
    leftToRightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [currentMonthGridView addGestureRecognizer:leftToRightSwipeGestureRecognizer];
    
    UISwipeGestureRecognizer *upToDownSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToRecedeMonth:)];
    upToDownSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [currentMonthGridView addGestureRecognizer:upToDownSwipeGestureRecognizer];
    
    UISwipeGestureRecognizer *rightToLeftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToAdvanceMonth:)];
    rightToLeftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [currentMonthGridView addGestureRecognizer:rightToLeftSwipeGestureRecognizer];
    
    UISwipeGestureRecognizer *downToUpSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToAdvanceMonth:)];
    downToUpSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [currentMonthGridView addGestureRecognizer:downToUpSwipeGestureRecognizer];
    
    CGRect scrollViewFrame = self.scrollView.frame;
    scrollViewFrame.size.height = (currentMonthGridView.numberOfLines + 1) * 38.0;
    self.scrollView.frame = scrollViewFrame;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height + [[UIImage imageNamed:@"topbar"] size].height + self.shadowImageView.frame.size.height);

    CGRect shadowFrame = self.shadowImageView.frame;
    shadowFrame.origin.y = scrollViewFrame.origin.y + scrollViewFrame.size.height;
    self.shadowImageView.frame = shadowFrame;

    UIView *nextMonthView = [[UIView alloc] initWithFrame:CGRectMake(0.0, currentMonthGridView.numberOfLines * 38.0, 320.0, 20.0)];
    UIView *previousMonthView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -20.0, 320.0, 20.0)];
    [self.scrollView addSubview:currentMonthGridView];
    [self.deck addObjectsFromArray:@[previousMonthView, currentMonthGridView, nextMonthView]];
}

- (NSArray *)getMarksDataWithDate:(NSDate *)date
{
    NSInteger days = [date daysInMonth];

    TKUDateInformation dateInformation = [date dateInformation];

    NSMutableArray *daysArray = [[NSMutableArray alloc] initWithCapacity:days];
    for (NSInteger i = 1; i <= days; i++) {
        dateInformation.day = i;
        if (self.dataSource != nil) {
            [daysArray addObject:[NSNumber numberWithBool:[self.dataSource calendarMonthView:self markForDay:[NSDate dateFromDateInformation:dateInformation]]]];
        } else {
            [daysArray addObject:[NSNumber numberWithBool:NO]];
        }
    }

    return daysArray;
}

- (void)moveCalendarAnimated:(BOOL)animated upwards:(BOOL)isMovingUp
{
    self.userInteractionEnabled = NO;

    UIView *previousMonthGridView = [self.deck objectAtIndex:0];
    UIView *currentMonthGridView = [self.deck objectAtIndex:1];
    UIView *nextMonthGridView = [self.deck objectAtIndex:2];

    if (isMovingUp == NO) {
        [self.scrollView bringSubviewToFront:previousMonthGridView];
        [self.scrollView bringSubviewToFront:currentMonthGridView];
        [self.scrollView sendSubviewToBack:nextMonthGridView];
    } else {
        [self.scrollView bringSubviewToFront:nextMonthGridView];
        [self.scrollView bringSubviewToFront:currentMonthGridView];
        [self.scrollView sendSubviewToBack:previousMonthGridView];
    }

    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorianCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[(TKUMonthGridView *) currentMonthGridView dateOfFirst]];
    [dateComponents setMonth:isMovingUp ? dateComponents.month + 1 : dateComponents.month - 1];
    NSDate *newDate = [gregorianCalendar dateFromComponents:dateComponents];

    self.monthYearString = [NSString stringWithFormat:@"%@ %@", [newDate tk_month], [newDate tk_year]];
    self.selectedMonthDate = newDate;

    NSArray *marksForSelectedMonth = [self getMarksDataWithDate:self.selectedMonthDate];
    NSInteger todayNumber = -1;
    TKUDateInformation dateInformation1 = [[NSDate date] dateInformation];
    TKUDateInformation dateInformation2 = [newDate dateInformation];
    if (dateInformation1.month == dateInformation2.month && dateInformation1.year == dateInformation2.year) {
        todayNumber = dateInformation1.day;
    }

    NSObject *monthGridView;
    if (isMovingUp) {
        monthGridView = nextMonthGridView;
    } else {
        monthGridView = previousMonthGridView;
    }

    [self.deck removeObject:monthGridView];

    if ([monthGridView isMemberOfClass:[TKUMonthGridView class]]) {
        [(TKUMonthGridView *)monthGridView setStartDate:newDate today:todayNumber marks:marksForSelectedMonth];
    } else {
        monthGridView = [[TKUMonthGridView alloc] initWithStartDate:newDate today:todayNumber marks:marksForSelectedMonth];

        UISwipeGestureRecognizer *leftToRightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToRecedeMonth:)];
        leftToRightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [(TKUMonthGridView *)monthGridView addGestureRecognizer:leftToRightSwipeGestureRecognizer];
        
        UISwipeGestureRecognizer *upToDownSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToRecedeMonth:)];
        upToDownSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
        [(TKUMonthGridView *)monthGridView addGestureRecognizer:upToDownSwipeGestureRecognizer];
        
        UISwipeGestureRecognizer *rightToLeftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToAdvanceMonth:)];
        rightToLeftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [(TKUMonthGridView *)monthGridView addGestureRecognizer:rightToLeftSwipeGestureRecognizer];
        
        UISwipeGestureRecognizer *downToUpSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedToAdvanceMonth:)];
        downToUpSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
        [(TKUMonthGridView *)monthGridView addGestureRecognizer:downToUpSwipeGestureRecognizer];
    }

    [(TKUMonthGridView *)monthGridView setDelegate:self];

    if (isMovingUp) {
        nextMonthGridView = (TKUMonthGridView *)monthGridView;
        [self.deck insertObject:monthGridView atIndex:1];
    } else {
        previousMonthGridView = (TKUMonthGridView *)monthGridView;
        [self.deck insertObject:monthGridView atIndex:0];
    }

    [self.scrollView addSubview:(UIView *)monthGridView];
    [self.scrollView sendSubviewToBack:(UIView *)monthGridView];

    if (isMovingUp) {
        monthGridView = previousMonthGridView;
    } else {
        monthGridView = nextMonthGridView;
    }

    [self.deck removeObject:monthGridView];
    [self.deck insertObject:monthGridView atIndex:0];

    CGRect monthGridViewFrame;
    if (isMovingUp) {
        monthGridViewFrame = nextMonthGridView.frame;
        monthGridViewFrame.origin.y = [(TKUMonthGridView *)currentMonthGridView numberOfLines] * 38.0;
    } else {
        monthGridViewFrame = previousMonthGridView.frame;
        monthGridViewFrame.origin.y = 0 - [(TKUMonthGridView *)previousMonthGridView numberOfLines] * 38.0;
    }

    if (isMovingUp && [nextMonthGridView isMemberOfClass:[TKUMonthGridView class]] &&  [(TKUMonthGridView *) nextMonthGridView weekdayOfFirst] == 1) {
        monthGridViewFrame.origin.y += 38.0;
    } else if (!isMovingUp && [nextMonthGridView isMemberOfClass:[TKUMonthGridView class]] && [(TKUMonthGridView *) currentMonthGridView weekdayOfFirst] == 1) {
        monthGridViewFrame.origin.y -= 38.0;
    }

    float scrollDistance;
    if (isMovingUp) {
        nextMonthGridView.frame = monthGridViewFrame;
        scrollDistance = nextMonthGridView.frame.origin.y;
    } else {
        previousMonthGridView.frame = monthGridViewFrame;
        scrollDistance = previousMonthGridView.frame.origin.y;
    }

    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationStopped:)];
    } else {
        [self performSelector:@selector(animationStopped:) withObject:self];
    }

    for (UIView *deckMonthGridView in self.deck) {
        CGPoint center = deckMonthGridView.center;
        center.y -= scrollDistance;
        deckMonthGridView.center = center;
    }

    monthGridViewFrame = self.scrollView.frame;
    
    if (isMovingUp) {
        monthGridViewFrame.size.height = ([(TKUMonthGridView *) nextMonthGridView numberOfLines] + 1) * 38.0;
    } else {
        monthGridViewFrame.size.height = ([(TKUMonthGridView *) previousMonthGridView numberOfLines] + 1) * 38.0;
    }
    self.scrollView.frame = monthGridViewFrame;

    CGRect shadowImageViewFrame = self.shadowImageView.frame;
    shadowImageViewFrame.origin.y = monthGridViewFrame.origin.y + monthGridViewFrame.size.height;
    self.shadowImageView.frame = shadowImageViewFrame;

    currentMonthGridView.alpha = 0;

    if (animated) {
        [UIView commitAnimations];
    }
    
    [self setNeedsDisplay];

    if ([self.delegate respondsToSelector:@selector(calendarMonthView:monthWillAppear:)]) {
        if (isMovingUp) {
            [self.delegate calendarMonthView:self monthWillAppear:[(TKUMonthGridView *) nextMonthGridView dateOfFirst]];
        } else {
            [self.delegate calendarMonthView:self monthWillAppear:[(TKUMonthGridView *) previousMonthGridView dateOfFirst]];
        }
    }
}

- (void)moveCalendarMonthsDownAnimated:(BOOL)animated
{
    [self moveCalendarAnimated:YES upwards:NO];
}

- (void)moveCalendarMonthsUpAnimated:(BOOL)animated
{
    [self moveCalendarAnimated:YES upwards:YES];
}

- (void)animationStopped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(calendarMonthView:monthDidAppear:)]) {
        [self.delegate calendarMonthView:self monthDidAppear:self.currentMonthDate];
    }

    [self.scrollView bringSubviewToFront:[self.deck objectAtIndex:1]];
    [[self.deck objectAtIndex:0] setAlpha:1];
    [[self.deck objectAtIndex:2] setAlpha:1];
    [[self.deck objectAtIndex:0] removeFromSuperview];
    [[self.deck objectAtIndex:2] removeFromSuperview];

    [self setUserInteractionEnabled:YES];
}

- (void)showCalendarMonth:(NSDate *)monthDate
{
    TKUMonthGridView *currentMonthGridView = [self.deck objectAtIndex:1];

    self.monthYearString = [NSString stringWithFormat:@"%@ %@", [monthDate tk_month], [monthDate tk_year]];
    self.selectedMonthDate = monthDate;

    NSArray *marks = [self getMarksDataWithDate:self.selectedMonthDate];
    NSInteger todayNumber = -1;
    TKUDateInformation todayDateInformation = [[NSDate date] dateInformation];
    TKUDateInformation monthDateInformation = [monthDate dateInformation];
    if (todayDateInformation.month == monthDateInformation.month && todayDateInformation.year == monthDateInformation.year) {
        todayNumber = todayDateInformation.day;
    }

    [currentMonthGridView setStartDate:monthDate today:todayNumber marks:marks];

    CGRect scrollViewFrame = self.scrollView.frame;
    scrollViewFrame.size.height = ([(TKUMonthGridView *) currentMonthGridView numberOfLines] + 1) * 38.0;
    self.scrollView.frame = scrollViewFrame;

    CGRect shadowImageViewFrame = self.shadowImageView.frame;
    shadowImageViewFrame.origin.y = scrollViewFrame.origin.y + scrollViewFrame.size.height;
    self.shadowImageView.frame = shadowImageViewFrame;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height + [[UIImage imageNamed:@"topbar"] size].height + self.shadowImageView.frame.size.height);

    [self setNeedsDisplay];

    if ([self.delegate respondsToSelector:@selector(calendarMonthView:monthWillAppear:)]) {
        [self.delegate calendarMonthView:self monthWillAppear:[currentMonthGridView dateOfFirst]];
    }
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 400)];
    if (self == nil) {
        return nil;
    }

    self.backgroundColor = [UIColor clearColor];
    
    TKUDateInformation todayDateInformation = [[NSDate date] dateInformation];
    todayDateInformation.second = todayDateInformation.minute = todayDateInformation.hour = 0;
    todayDateInformation.day = 1;
    self.currentMonthDate = [NSDate dateFromDateInformation:todayDateInformation];
    
    self.monthYearString = [[NSString stringWithFormat:@"%@ %@", [self.currentMonthDate tk_month], [self.currentMonthDate tk_year]] copy];
    self.selectedMonthDate = self.currentMonthDate;
    
    [self loadButtons];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, [[UIImage imageNamed:@"topbar"] size].height, 320.0, 460.0 - [[UIImage imageNamed:@"topbar"] size].height)];
    self.scrollView.contentSize = CGSizeMake(320, 260);
    [self addSubview:self.scrollView];
    self.scrollView.scrollEnabled = NO;
    self.scrollView.backgroundColor = [UIColor colorWithRed:251.0 / 255.0 green:251.0 / 255.0 blue:251.0 / 255.0 alpha:1.0];
    
    self.shadowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shadow"]];
    [self addSubview:self.shadowImageView];
    
    self.deck = [[NSMutableArray alloc] initWithCapacity:3];
    [self loadInitialGrids];
    
    return self;
}

- (void)reload
{
    if (self.deck && self.deck.count > 1) {
        TKUMonthGridView *currentMonthGridView = [self.deck objectAtIndex:1];
        currentMonthGridView.marks = [self getMarksDataWithDate:currentMonthGridView.dateOfFirst];
        [currentMonthGridView resetMarks];
    }
}

- (void)selectDate:(NSDate *)date
{
    self.selectedDate = date;

    if (self.deck && self.deck.count > 1) {
        // Get the new month view
        TKUMonthGridView *currentMonthGridView = [self.deck objectAtIndex:1];

        TKUDateInformation dateInformation = [date dateInformation];
        dateInformation.hour = dateInformation.minute = dateInformation.second = 0;

        TKUDateInformation currentDateOfFirstDateInformation = [currentMonthGridView.dateOfFirst dateInformation];
        currentDateOfFirstDateInformation.hour = currentDateOfFirstDateInformation.minute = currentDateOfFirstDateInformation.second = 0;

        NSInteger difference = [[NSDate dateFromDateInformation:dateInformation] differenceInMonthsTo:[NSDate dateFromDateInformation:currentDateOfFirstDateInformation]];
        if (difference == 0) {
            // Month is already selected
            // Do nothing
        } else if (difference < 0) {
            // Going up
            if (difference == -1) {
                [self moveCalendarMonthsUpAnimated:NO];
            } else {
                [self showCalendarMonth:date];
            }
        } else {
            // Going down
            if (difference == 1) {
                [self moveCalendarMonthsDownAnimated:NO];
            } else {
                [self showCalendarMonth:date];
            }
        }
        currentMonthGridView = [self.deck objectAtIndex:1];

        // Select Date
        [currentMonthGridView selectDay:dateInformation.day];
    }
}

- (NSDate *)monthDate
{
    return self.currentMonthDate;
}

#pragma mark MONTH VIEW DELEGATE METHODS

- (void)previousMonthDayWasSelected:(NSString *)day
{
    [self moveCalendarMonthsDownAnimated:YES];
    [[self.deck objectAtIndex:1] selectDay:[day integerValue]];

    TKUMonthGridView *currentMonthGridView = [self.deck objectAtIndex:1];
    NSDate *dateOfFirst = currentMonthGridView.dateOfFirst;
    TKUDateInformation dateOfFirstDateInformation = [dateOfFirst dateInformation];
    dateOfFirstDateInformation.day = day.integerValue;

    self.selectedDate = [NSDate dateFromDateInformation:dateOfFirstDateInformation];

    if ([self.delegate respondsToSelector:@selector(calendarMonthView:dateWasSelected:)]) {
        [self.delegate calendarMonthView:self dateWasSelected:[self selectedDate]];
    }
}

- (void)nextMonthDayWasSelected:(NSString *)day
{
    [self moveCalendarMonthsUpAnimated:YES];
    [[self.deck objectAtIndex:1] selectDay:[day integerValue]];

    TKUMonthGridView *currentMonthGridView = [self.deck objectAtIndex:1];
    NSDate *dateOfFirst = currentMonthGridView.dateOfFirst;
    TKUDateInformation dateOfFirstDateInformation = [dateOfFirst dateInformation];
    dateOfFirstDateInformation.day = day.integerValue;

    self.selectedDate = [NSDate dateFromDateInformation:dateOfFirstDateInformation];

    if ([self.delegate respondsToSelector:@selector(calendarMonthView:dateWasSelected:)]) {
        [self.delegate calendarMonthView:self dateWasSelected:[self selectedDate]];
    }
}

- (void)dateWasSelected:(NSArray *)array
{
    TKUMonthGridView *monthGridView = [array objectAtIndex:0];
    NSString *dayNumber = [array objectAtIndex:1];
    NSDate *dateOfFirst = monthGridView.dateOfFirst;
    TKUDateInformation dateOfFirstDateInformation = [dateOfFirst dateInformation];
    dateOfFirstDateInformation.day = dayNumber.integerValue;

    self.selectedDate = [NSDate dateFromDateInformation:dateOfFirstDateInformation];

    if ([self.delegate respondsToSelector:@selector(calendarMonthView:dateWasSelected:)]) {
        [self.delegate calendarMonthView:self dateWasSelected:[self selectedDate]];
    }
}

#pragma mark LEFT & RIGHT BUTTON ACTIONS

- (void)leftButtonTapped
{
    [self moveCalendarMonthsDownAnimated:YES];
    [self selectDayInMonth];
}

- (void)rightButtonTapped
{
    [self moveCalendarMonthsUpAnimated:YES];
    [self selectDayInMonth];
}

- (void)swipedToRecedeMonth:(UIGestureRecognizer *)gestureRecognizer
{
    [self moveCalendarMonthsDownAnimated:YES];
    [self selectDayInMonth];
}

- (void)swipedToAdvanceMonth:(UIGestureRecognizer *)gestureRecognizer
{
    [self moveCalendarMonthsUpAnimated:YES];
    [self selectDayInMonth];
}

- (void)selectDayInMonth
{
    TKUDateInformation selectedDateInformation = [self.selectedDate dateInformation];
    selectedDateInformation.hour = selectedDateInformation.minute = selectedDateInformation.second = 0;

    TKUDateInformation selectedMonthDateInformation = [self.selectedMonthDate dateInformation];
    selectedMonthDateInformation.hour = selectedMonthDateInformation.minute = selectedMonthDateInformation.second = 0;

    NSInteger difference = [[NSDate dateFromDateInformation:selectedDateInformation] differenceInMonthsTo:[NSDate dateFromDateInformation:selectedMonthDateInformation]];
    if (difference == 0) {
        [[self.deck objectAtIndex:1] selectDay:selectedDateInformation.day];
    }
}

- (void)drawRect:(CGRect)rect
{
    [[UIImage imageNamed:@"topbar"] drawAtPoint:CGPointMake(0, 0)];

    [self drawDayLabels:rect];
    [self drawMonthLabel:rect];
}

- (void)drawMonthLabel:(CGRect)dirtyRect
{
    if (self.monthYearString == nil) {
        return;
    }

    CGFloat height = 38.0;
    CGFloat width = dirtyRect.size.width;

    UIFont *font = [UIFont boldSystemFontOfSize:20.0];
    CGSize size = [self.monthYearString sizeWithFont:font];
    CGFloat x = ((width - size.width) / 2);
    CGFloat y = ((height - size.height) / 2);

    [[UIColor colorWithWhite:1.0 alpha:0.6] set];
    [self.monthYearString drawAtPoint:CGPointMake(x, y + 1) forWidth:size.width withFont:font lineBreakMode:NSLineBreakByTruncatingTail];

    [[UIColor colorWithRed:82.0 / 255.0 green:82.0 / 255.0 blue:82.0 / 255.0 alpha:1.0] set];
    [self.monthYearString drawAtPoint:CGPointMake(x, y) forWidth:size.width withFont:font lineBreakMode:NSLineBreakByTruncatingTail];
}

- (void)drawDayLabels:(CGRect)rect
{
    NSString *mon = NSLocalizedString(@"Mon", @"Mon");
    NSString *tue = NSLocalizedString(@"Tue", @"Tue");
    NSString *wed = NSLocalizedString(@"Wed", @"Wed");
    NSString *thu = NSLocalizedString(@"Thu", @"Thu");
    NSString *fri = NSLocalizedString(@"Fri", @"Fri");
    NSString *sat = NSLocalizedString(@"Sat", @"Sat");
    NSString *sun = NSLocalizedString(@"Sun", @"Sun");

    // Calendar starting on Monday instead of Sunday (Australia, Europe agains US american calendar)
    NSArray *days;
    CFCalendarRef currentCalendar = CFCalendarCopyCurrent();
    if (CFCalendarGetFirstWeekday(currentCalendar) == 2) {
        days = [NSArray arrayWithObjects:mon, tue, wed, thu, fri, sat, sun, nil];
    } else {
        days = [NSArray arrayWithObjects:sun, mon, tue, wed, thu, fri, sat, nil];
    }
    CFRelease(currentCalendar);

    UIFont *font = [UIFont boldSystemFontOfSize:10];
    [[UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0] set];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    NSInteger i = 0;
    for (NSString *day in days) {
        [day drawInRect:CGRectMake(i * 46.0, 39.0, 45.0, 19.0) withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
        i++;
    }

    CGContextRestoreGState(context);
}

@end

@implementation TKUMonthGridView

- (int)daysInPreviousMonth
{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorianCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:self.dateOfFirst];
    [dateComponents setDay:1];
    [dateComponents setMonth:dateComponents.month - 1];

    return [[gregorianCalendar dateFromComponents:dateComponents] daysInMonth];
}

- (id)initWithStartDate:(NSDate *)startDate today:(NSInteger)todayDay marks:(NSArray *)marksArray
{
    self = [self initWithFrame:CGRectMake(0, 0, 320, 320)];
    if (self == nil) {
        return nil;
    }

    [self setStartDate:startDate today:todayDay marks:marksArray];
    self.backgroundColor = [UIColor colorWithRed:251.0/255.0 green:251.0/255.0 blue:251.0/255.0 alpha:1.0];

    return self;
}

- (void)buildGrid
{
    self.dayTiles = [[NSMutableArray alloc] init];

    NSInteger position = self.weekdayOfFirst;
    NSInteger line = 0;

    NSInteger daysInPreviousMonth = [self daysInPreviousMonth];
    NSInteger daysInMonth = [self.dateOfFirst daysInMonth];
    NSInteger lead = daysInPreviousMonth - (position - 2);

    for (NSInteger i = 1; i < position; i++) {
        CGFloat x = (i - 1) * 46.0 - 1;
        CGFloat y = 0.0;
        CGFloat width = 46.0;
        CGFloat height = 38.0;
        TKUCalendarDayView *dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        dayView.active = NO;
        dayView.dayText = [NSString stringWithFormat:@"%d", lead];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dayTapped:)];
        [dayView addGestureRecognizer:tapGestureRecognizer];

        [self addSubview:dayView];
        [self.dayTiles addObject:dayView];
        lead++;
    }

    BOOL isCurrentMonth = NO;
    if (self.todaysDay > 0) {
        isCurrentMonth = YES;
    }

    for (NSInteger i = 1; i <= daysInMonth; i++) {
        CGFloat x = (position - 1) * 46.0 - 1;
        CGFloat y = line * 38.0;
        CGFloat width = 46.0;
        CGFloat height = 38.0;
        TKUCalendarDayView *dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        dayView.marked = [[self.marks objectAtIndex:i - 1] boolValue];
        dayView.today = (isCurrentMonth && i == self.todaysDay);
        dayView.dayText = [NSString stringWithFormat:@"%d", i];

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dayTapped:)];
        [dayView addGestureRecognizer:tapGestureRecognizer];

        // Set the tag as the day view
        // Will be used in order to reset marks
        // Each day view is easily accessible using viewWithTag
        dayView.tag = i;

        [self addSubview:dayView];
        [self.dayTiles addObject:dayView];

        if (position == 7) {
            position = 1;
            line++;
        } else {
            position++;
        }
    }

    if (position != 1) {
        NSInteger counter = 1;
        for (NSInteger i = position; i < 8; i++) {
            CGFloat x = (i - 1) * 46.0 - 1;
            CGFloat y = 0.0;
            CGFloat width = 46.0;
            CGFloat height = 38.0;
            TKUCalendarDayView *dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectMake(x, y, width, height)];
            dayView.dayText = [NSString stringWithFormat:@"%d", counter];
            dayView.active = NO;

            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dayTapped:)];
            [dayView addGestureRecognizer:tapGestureRecognizer];

            [self addSubview:dayView];
            [self.dayTiles addObject:dayView];
            counter++;
        }
    }

    CGRect frame = self.frame;
    frame.size.height = (line + 1) * 38.0;
    self.frame = frame;

    self.numberOfLines = line;
    if (position == 1) {
        self.numberOfLines--;
    }
}

- (void)resetMarks
{
    for (NSInteger i = 1; i <= self.marks.count; i++) {
        TKUCalendarDayView *dayView = (TKUCalendarDayView *)[self viewWithTag:i];
        dayView.marked = [[self.marks objectAtIndex:i - 1] boolValue];
    }
    
    [self setNeedsDisplay];
}

- (TKUCalendarDayView *)dequeueReusableDayView
{
    if ([self.reusableDayViews count] > 0) {
        TKUCalendarDayView *dayView = [self.reusableDayViews objectAtIndex:0];
        [self.reusableDayViews removeObjectAtIndex:0];
        return dayView;
    }
    
    return nil;
}

- (void)build
{
    [self.reusableDayViews addObjectsFromArray:self.dayTiles];
    self.dayTiles = [[NSMutableArray alloc] init];

    NSInteger position = self.weekdayOfFirst;
    NSInteger lineNumber = 0;

    NSInteger daysInPreviousMonth = [self daysInPreviousMonth];
    NSInteger daysInMonth = [self.dateOfFirst daysInMonth];
    NSInteger lead = daysInPreviousMonth - (position - 2);

    TKUCalendarDayView *dayView;

    for (NSInteger i = 1; i < position; i++) {
        dayView = [self dequeueReusableDayView];
        if (dayView == nil) {
            dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectZero];
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dayTapped:)];
            [dayView addGestureRecognizer:tapGestureRecognizer];

        }
        
        CGFloat x = (i - 1) * 46.0 - 1.0;
        CGFloat y = 0.0;
        CGFloat width = 46.0;
        CGFloat height = 38.0;
        dayView.frame = CGRectMake(x, y, width, height);
        [dayView setString:[NSString stringWithFormat:@"%d", lead] selected:NO active:NO today:NO marked:NO];

        [self addSubview:dayView];
        [self.dayTiles addObject:dayView];

        lead++;
    }

    BOOL isCurrentMonth = NO;
    if (self.todaysDay > 0) {
        isCurrentMonth = YES;
    }

    for (NSInteger i = 1; i <= daysInMonth; i++) {
        dayView = [self dequeueReusableDayView];
        if (dayView == nil) {
            dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectZero];
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dayTapped:)];
            [dayView addGestureRecognizer:tapGestureRecognizer];

        }

        CGFloat x = (position - 1) * 46.0 - 1.0;
        CGFloat y = lineNumber * 38.0;
        CGFloat width = 46.0;
        CGFloat height = 38.0;
        dayView.frame = CGRectMake(x, y, width, height);

        BOOL isToday = (isCurrentMonth && i == self.todaysDay);

        [dayView setString:[NSString stringWithFormat:@"%d", i] selected:NO active:YES today:isToday marked:[[self.marks objectAtIndex:i - 1] boolValue]];

        // Set the tag as the day view
        // Will be used in order to reseet marks
        // Each day view is easily accessible using viewWithTag
        dayView.tag = i;

        [self addSubview:dayView];
        [self.dayTiles addObject:dayView];

        if (position == 7) {
            position = 1;
            lineNumber++;
        } else {
            position++;
        }
    }

    if (position != 1) {
        NSInteger counter = 1;
        for (NSInteger i = position; i < 8; i++) {
            dayView = [self dequeueReusableDayView];
            if (dayView == nil) {
                dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectZero];
                UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dayTapped:)];
                [dayView addGestureRecognizer:tapGestureRecognizer];

            }

            CGFloat x = (i - 1) * 46.0 - 1.0;
            CGFloat y = lineNumber * 38.0;
            CGFloat width = 46.0;
            CGFloat height = 38.0;
            dayView.frame = CGRectMake(x, y, width, height);
            [dayView setString:[NSString stringWithFormat:@"%d", counter] selected:NO active:NO today:NO marked:NO];

            [self addSubview:dayView];
            [self.dayTiles addObject:dayView];
            counter++;
        }
    }

    CGRect frame = self.frame;
    frame.size.height = (lineNumber + 1) * 38.0;
    self.frame = frame;

    self.numberOfLines = lineNumber;
    if (position == 1) {
        self.numberOfLines--;
    }
}

- (void)selectDay:(int)theDayNumber
{
    NSInteger i = 0;
    while (i < [self.dayTiles count]) {
        if ([[[self.dayTiles objectAtIndex:i] dayText] integerValue] == 1) {
            break;
        }
        i++;
    }

    [self.selectedDayView setSelected:NO];
    self.selectedDayView = [self.dayTiles objectAtIndex:i + theDayNumber - 1];
    [[self.dayTiles objectAtIndex:i + theDayNumber - 1] setSelected:YES];

    [self bringSubviewToFront:self.selectedDayView];
}

- (void)dayTapped:(UIGestureRecognizer *)gestureRecognizer
{
    TKUCalendarDayView *selectedDayView = (TKUCalendarDayView *)gestureRecognizer.view;
    
    if (selectedDayView.isActive == NO) {
        if ([selectedDayView.dayText integerValue] > 15) {
            [self.delegate performSelector:@selector(previousMonthDayWasSelected:) withObject:selectedDayView.dayText];
        } else {
            [self.delegate performSelector:@selector(nextMonthDayWasSelected:) withObject:selectedDayView.dayText];
        }
        
        return;
    }
    
    self.selectedDayView.selected = NO;
    
    [self bringSubviewToFront:selectedDayView];
    
    selectedDayView.selected = YES;
    self.selectedDayView = selectedDayView;
    
    [self.delegate performSelector:@selector(dateWasSelected:) withObject:[NSArray arrayWithObjects:self, selectedDayView.dayText, nil]];
}

- (void)setStartDate:(NSDate *)startDate today:(NSInteger)todayDay marks:(NSArray *)marksArray
{
    TKUDateInformation startDateInformation = [startDate dateInformation];
    startDateInformation.day  = 1;
    self.dateOfFirst = [NSDate dateFromDateInformation:startDateInformation];

    // Calendar starting on Monday instead of Sunday (Australia, Europe against US american calendar)
    self.weekdayOfFirst = [self.dateOfFirst weekdayWithMondayFirst];
    self.todaysDay = todayDay;
    self.marks = marksArray;

    if (self.dayTiles == nil) {
        self.dayTiles = [[NSMutableArray alloc] init];
        self.reusableDayViews = [[NSMutableArray alloc] init];
    }

    [self build];
}

@end

@implementation TKUCalendarDayView

- (id)initWithFrame:(CGRect)frame string:(NSString *)string selected:(BOOL)selected active:(BOOL)active today:(BOOL)today marked:(BOOL)marked
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }
    
    [self setString:string selected:selected active:active today:today marked:marked];
    
    return self;
}

- (void)setString:(NSString *)dayText selected:(BOOL)selected active:(BOOL)active today:(BOOL)today marked:(BOOL)mark
{
    self.dayText = dayText;
    self.selected = selected;
    self.active = active;
    self.today = today;
    self.marked = mark;
    
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }

    self.active = YES;
    self.today = NO;
    self.marked = NO;
    self.selected = NO;
    self.opaque = YES;

    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 251.0/255.0, 251.0/255.0, 251.0/255.0, 1.0);
    CGContextFillRect(context, rect);

    UIImage *dateCellImage = nil;
    UIColor *textColor = [UIColor whiteColor];

    if (self.isActive == NO) {
        textColor = [UIColor colorWithRed:204.0 / 255.0 green:204.0 / 255.0 blue:204.0 / 255.0 alpha:1.0];
    } else if (self.isToday && self.isSelected) {
        dateCellImage = [UIImage imageNamed:@"todayselected"];
    } else if (self.isToday) {
        textColor = [UIColor colorWithRed:82.0 / 255.0 green:82.0 / 255.0 blue:82.0 / 255.0 alpha:1.0];
        dateCellImage = [UIImage imageNamed:@"today"];
    } else if (self.isSelected) {
        dateCellImage = [UIImage imageNamed:@"datecellselected"];
    } else {
        textColor = [UIColor colorWithRed:82.0 / 255.0 green:82.0 / 255.0 blue:82.0 / 255.0 alpha:1.0];
    }

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    if (dateCellImage != nil) {
        CGFloat imageX = ((width - dateCellImage.size.width) / 2);
        CGFloat imageY = ((height - dateCellImage.size.height) / 2);
        [dateCellImage drawAtPoint:CGPointMake(imageX, imageY)];
    }

    [textColor set];

    UIFont *font = [UIFont systemFontOfSize:18.0];
    CGSize size = [self.dayText sizeWithFont:font];
    CGFloat x = ((width - size.width) / 2);
    CGFloat y = ((height - size.height) / 2);
    
    [self.dayText drawAtPoint:CGPointMake(x, y) forWidth:size.width withFont:font lineBreakMode:NSLineBreakByWordWrapping];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    [self setNeedsDisplay];
}

- (void)setToday:(BOOL)today
{
    if (today == _today) {
        return;
    }
    
    _today = !_today;
    [self setNeedsDisplay];
}

- (void)setActive:(BOOL)active
{
    if (_active == active) {
        return;
    }
    
    _active = active;
    [self setNeedsDisplay];
}

- (void)setMarked:(BOOL)marked
{
    if (_marked == marked) {
        return;
    }
    
    _marked = !_marked;
    [self setNeedsDisplay];
}

@end