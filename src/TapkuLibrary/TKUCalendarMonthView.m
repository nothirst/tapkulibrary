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

#import "TKUGlobal.h"
#import "NSDate+TKUAdditions.h"
#import "UIImage+TKUAdditions.h"
#import "UIView+TKUAdditions.h"

@interface TKUMonthGridView : UIView

@property TKUCalendarDayView *selectedDay;
@property int lines;
@property int todayNumber;
@property (unsafe_unretained, nonatomic) id delegate;
@property int weekdayOfFirst;
@property NSDate *dateOfFirst;
@property (nonatomic, strong) NSArray *marks;
@property NSMutableArray *dayTiles;
@property NSMutableArray *graveYard;

- (id)initWithStartDate:(NSDate *)theDate today:(NSInteger)todayDay marks:(NSArray *)marksArray;
- (void)selectDay:(int)theDayNumber;
- (void)resetMarks;
- (void)setStartDate:(NSDate *)theDate today:(NSInteger)todayDay marks:(NSArray *)marksArray;
- (void)buildGrid;

@end

@interface TKUCalendarDayView : UIView

- (id)initWithFrame:(CGRect)frame string:(NSString *)string selected:(BOOL)sel active:(BOOL)act today:(BOOL)tdy marked:(BOOL)mark;
- (void)setString:(NSString *)string selected:(BOOL)sel active:(BOOL)act today:(BOOL)tdy marked:(BOOL)mark;

@property (copy, nonatomic) NSString *str;
@property (assign, nonatomic) BOOL selected;
@property (assign, nonatomic) BOOL active;
@property (assign, nonatomic) BOOL today;
@property (assign, nonatomic) BOOL marked;

@end

@interface TKUCalendarMonthView ()

@property UIButton *left;
@property UIButton *right;
@property UIScrollView *scrollView;
@property NSDate *currentMonth;
@property UIImageView *shadow;
@property NSMutableArray *deck;
@property NSDate *selectedMonth;
@property NSString *monthYear;

- (void)loadButtons;
- (void)loadInitialGrids;
- (NSArray *)getMarksDataWithDate:(NSDate *)date;
- (void)drawMonthLabel:(CGRect)rect;
- (void)drawDayLabels:(CGRect)rect;
- (void)moveCalendarMonthsDownAnimated:(BOOL)animated;
- (void)moveCalendarMonthsUpAnimated:(BOOL)animated;
- (void)setCurrentMonth:(NSDate *)d;
- (void)setSelectedMonth:(NSDate *)d;
- (void)showCalendarMonth:(NSDate *)theD;
- (void)selectDayInMonth;

@end

@implementation TKUCalendarMonthView

- (void)loadButtons
{
    self.left = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.left addTarget:self action:@selector(leftButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.left setImage:[UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/leftarrow.png")] forState:0];
    [self addSubview:self.left];
    self.left.frame = CGRectMake(10, 0, 44, 42);

    self.right = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.right setImage:[UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/rightarrow.png")] forState:0];
    [self.right addTarget:self action:@selector(rightButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.right];
    self.right.frame = CGRectMake(320 - 56, 0, 44, 42);
}

- (void)loadInitialGrids
{
    NSArray *ar = [self getMarksDataWithDate:self.currentMonth];

    TKUMonthGridView *currentGrid = [[TKUMonthGridView alloc] initWithStartDate:self.currentMonth
                                                                        today:[[NSDate date] dateInformation].day
                                                                        marks:ar];

    [currentGrid setDelegate:self];

    CGRect r = self.scrollView.frame;
    r.size.height = (currentGrid.lines + 1) * 44;
    self.scrollView.frame = r;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height  + 44);

    CGRect imgrect = self.shadow.frame;
    imgrect.origin.y = r.size.height - 132;
    self.shadow.frame = imgrect;

    UIView *next = [[UIView alloc] initWithFrame:CGRectMake(0, currentGrid.lines * 44, 320, 20)];
    UIView *prev = [[UIView alloc] initWithFrame:CGRectMake(0, -20, 320, 20)];
    [self.scrollView addSubview:currentGrid];
    [self.deck addObjectsFromArray:[NSArray arrayWithObjects:prev, currentGrid, next, nil]];
}

- (NSArray *)getMarksDataWithDate:(NSDate *)date
{
    int days = [date daysInMonth];

    TKUDateInformation info = [date dateInformation];

    NSMutableArray *ar = [[NSMutableArray alloc] initWithCapacity:days];
    for (int i = 1; i <= days; i++) {
        info.day = i;
        if (self.dataSource != nil) {
            [ar addObject:[NSNumber numberWithBool:[self.dataSource calendarMonthView:self markForDay:[NSDate dateFromDateInformation:info]]]];
        } else {
            [ar addObject:[NSNumber numberWithBool:NO]];
        }
    }

    NSArray *array = [NSArray arrayWithArray:ar];

    return array;
}

- (void)moveCalendarAnimated:(BOOL)animated upwards:(BOOL)up
{
    [self setUserInteractionEnabled:NO];
    UIView *prev = [self.deck objectAtIndex:0];
    UIView *current = [self.deck objectAtIndex:1];
    UIView *next = [self.deck objectAtIndex:2];

    if (!up) {
        [self.scrollView bringSubviewToFront:prev];
        [self.scrollView bringSubviewToFront:current];
        [self.scrollView sendSubviewToBack:next];
    } else {
        [self.scrollView bringSubviewToFront:next];
        [self.scrollView bringSubviewToFront:current];
        [self.scrollView sendSubviewToBack:prev];
    }

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[(TKUMonthGridView *) current dateOfFirst]];
    [comp setMonth:up ? comp.month + 1:comp.month - 1];
    NSDate *newDate = [gregorian dateFromComponents:comp];

    [self setMonthYear:[NSString stringWithFormat:@"%@ %@", [newDate tk_month], [newDate tk_year]]];
    [self setSelectedMonth:newDate];

    NSArray *ar = [self getMarksDataWithDate:self.selectedMonth];
    int todayNumber = -1;
    TKUDateInformation info1 = [[NSDate date] dateInformation];
    TKUDateInformation info2 = [newDate dateInformation];
    if (info1.month == info2.month && info1.year == info2.year) {
        todayNumber = info1.day;
    }

    NSObject *obj;
    if (up) {
        obj = next;
    } else {
        obj = prev;
    }

    [self.deck removeObject:obj];

    if ([obj isMemberOfClass:[TKUMonthGridView class]]) {
        [(TKUMonthGridView *) obj setStartDate:newDate today:todayNumber marks:ar];
    } else {
        obj = [[TKUMonthGridView alloc] initWithStartDate:newDate today:todayNumber marks:ar];
    }

    [(TKUMonthGridView *) obj setDelegate:self];

    if (up) {
        next = (TKUMonthGridView *)obj;
        [self.deck insertObject:obj atIndex:1];
    } else {
        prev = (TKUMonthGridView *)obj;
        [self.deck insertObject:obj atIndex:0];
    }

    [self.scrollView addSubview:(UIView *)obj];
    [self.scrollView sendSubviewToBack:(UIView *)obj];

    if (up) {
        obj = prev;
    } else {
        obj = next;
    }

    [self.deck removeObject:obj];
    [self.deck insertObject:obj atIndex:0];

    CGRect r;
    if (up) {
        r = next.frame;
        r.origin.y = [(TKUMonthGridView *) current lines] *  44;
    } else {
        r = prev.frame;
        r.origin.y = 0 - [(TKUMonthGridView *) prev lines] *  44;
    }

    if (up && [next isMemberOfClass:[TKUMonthGridView class]] &&  [(TKUMonthGridView *) next weekdayOfFirst] == 1) {
        r.origin.y += 44;
    } else if (!up && [next isMemberOfClass:[TKUMonthGridView class]] && [(TKUMonthGridView *) current weekdayOfFirst] == 1) {
        r.origin.y -= 44;
    }

    float scrol;
    if (up) {
        next.frame = r;
        scrol = next.frame.origin.y;
    } else {
        prev.frame = r;
        scrol = prev.frame.origin.y;
    }

    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationStopped:)];
    } else {
        [self performSelector:@selector(animationStopped:) withObject:self];
    }

    for (UIView *m in self.deck) {
        CGPoint c = m.center;
        c.y -= scrol;
        m.center = c;
    }
    r = self.scrollView.frame;
    if (up) {
        r.size.height = ([(TKUMonthGridView *) next lines] + 1) * 44;
    } else {
        r.size.height = ([(TKUMonthGridView *) prev lines] + 1) * 44;
    }
    self.scrollView.frame = r;

    CGRect imgrect = self.shadow.frame;
    imgrect.origin.y = r.size.height - 132;
    self.shadow.frame = imgrect;

    current.alpha = 0;
    if (animated) {
        [UIView commitAnimations];
    }
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height + 44);
    [self setNeedsDisplay];

    if ([self.delegate respondsToSelector:@selector(calendarMonthView:monthWillAppear:)]) {
        if (up) {
            [self.delegate calendarMonthView:self monthWillAppear:[(TKUMonthGridView *) next dateOfFirst]];
        } else {
            [self.delegate calendarMonthView:self monthWillAppear:[(TKUMonthGridView *) prev dateOfFirst]];
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
        [self.delegate calendarMonthView:self monthDidAppear:self.currentMonth];
    }

    [self.scrollView bringSubviewToFront:[self.deck objectAtIndex:1]];
    [[self.deck objectAtIndex:0] setAlpha:1];
    [[self.deck objectAtIndex:2] setAlpha:1];
    [[self.deck objectAtIndex:0] removeFromSuperview];
    [[self.deck objectAtIndex:2] removeFromSuperview];

    [self setUserInteractionEnabled:YES];
}

- (void)showCalendarMonth:(NSDate *)theD
{
    TKUMonthGridView *current = [self.deck objectAtIndex:1];

    [self setMonthYear:[NSString stringWithFormat:@"%@ %@", [theD tk_month], [theD tk_year]]];
    [self setSelectedMonth:theD];

    NSArray *ar = [self getMarksDataWithDate:self.selectedMonth];
    int todayNumber = -1;
    TKUDateInformation info1 = [[NSDate date] dateInformation];
    TKUDateInformation info2 = [theD dateInformation];
    if (info1.month == info2.month && info1.year == info2.year) {
        todayNumber = info1.day;
    }

    [current setStartDate:theD today:todayNumber marks:ar];

    CGRect r = self.scrollView.frame;
    r.size.height = ([(TKUMonthGridView *) current lines] + 1) * 44;
    self.scrollView.frame = r;

    CGRect imgrect = self.shadow.frame;
    imgrect.origin.y = r.size.height - 132;
    self.shadow.frame = imgrect;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height + 44);

    [self setNeedsDisplay];

    if ([self.delegate respondsToSelector:@selector(calendarMonthView:monthWillAppear:)]) {
        [self.delegate calendarMonthView:self monthWillAppear:[current dateOfFirst]];
    }
}

- (id)init
{
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 400)]) {
        self.backgroundColor = [UIColor clearColor];

        TKUDateInformation info = [[NSDate date] dateInformation];
        info.second = info.minute = info.hour = 0;
        info.day = 1;
        [self setCurrentMonth:[NSDate dateFromDateInformation:info]];

        self.monthYear = [[NSString stringWithFormat:@"%@ %@", [self.currentMonth tk_month], [self.currentMonth tk_year]] copy];
        [self setSelectedMonth:self.currentMonth];

        [self loadButtons];

        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 44, 320, 460 - 44)];
        self.scrollView.contentSize = CGSizeMake(320, 260);
        [self addSubview:self.scrollView];
        self.scrollView.scrollEnabled = NO;
        self.scrollView.backgroundColor = [UIColor colorWithRed:222 / 255.0 green:222 / 255.0 blue:225 / 255.0 alpha:1];

        self.shadow = [[UIImageView alloc] initWithImage:[UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/shadow.png")]];
        self.deck = [[NSMutableArray alloc] initWithCapacity:3];

        [self addSubview:self.shadow];
        [self loadInitialGrids];
    }
    return self;
}

- (void)reload
{
    if (self.deck && self.deck.count > 1) {
        TKUMonthGridView *current = [self.deck objectAtIndex:1];
        current.marks = [self getMarksDataWithDate:current.dateOfFirst];
        [current resetMarks];
    }
}

- (void)selectDate:(NSDate *)date
{
    [self setSelectedDate:date];
    if (self.deck && self.deck.count > 1) {
        // Get the new month view
        TKUMonthGridView *current = [self.deck objectAtIndex:1];

        TKUDateInformation info1 = [date dateInformation];
        info1.hour = info1.minute = info1.second = 0;

        TKUDateInformation info2 = [current.dateOfFirst dateInformation];
        info2.hour = info2.minute = info2.second = 0;

        NSInteger difference = [[NSDate dateFromDateInformation:info1] differenceInMonthsTo:[NSDate dateFromDateInformation:info2]];
        if (difference == 0) {
            // Month is already selected
            // Do nothing
        } else if (difference < 0) {
            // Going up
            if (difference == -1) {
                [self moveCalendarMonthsUpAnimated:FALSE];
            } else {
                [self showCalendarMonth:date];
            }
        } else {
            // Going down
            if (difference == 1) {
                [self moveCalendarMonthsDownAnimated:FALSE];
            } else {
                [self showCalendarMonth:date];
            }
        }
        current = [self.deck objectAtIndex:1];
        // Select Date
        [current selectDay:info1.day];
    }
}

- (NSDate *)monthDate
{
    return self.currentMonth;
}

#pragma mark MONTH VIEW DELEGATE METHODS

- (void)previousMonthDayWasSelected:(NSString *)day
{
    [self moveCalendarMonthsDownAnimated:TRUE];
    [[self.deck objectAtIndex:1] selectDay:day.intValue];

    TKUMonthGridView *calendarMonth = [self.deck objectAtIndex:1];
    NSDate *date = calendarMonth.dateOfFirst;
    TKUDateInformation info = [date dateInformation];
    info.day = day.intValue;

    [self setSelectedDate:[NSDate dateFromDateInformation:info]];
    if ([self.delegate respondsToSelector:@selector(calendarMonthView:dateWasSelected:)]) {
        [self.delegate calendarMonthView:self dateWasSelected:[self selectedDate]];
    }
}

- (void)nextMonthDayWasSelected:(NSString *)day
{
    [self moveCalendarMonthsUpAnimated:TRUE];
    [[self.deck objectAtIndex:1] selectDay:day.intValue];

    TKUMonthGridView *calendarMonth = [self.deck objectAtIndex:1];
    NSDate *date = calendarMonth.dateOfFirst;
    TKUDateInformation info = [date dateInformation];
    info.day = day.intValue;

    [self setSelectedDate:[NSDate dateFromDateInformation:info]];
    if ([self.delegate respondsToSelector:@selector(calendarMonthView:dateWasSelected:)]) {
        [self.delegate calendarMonthView:self dateWasSelected:[self selectedDate]];
    }
}

- (void)dateWasSelected:(NSArray *)array
{
    TKUMonthGridView *calendarMonth = [array objectAtIndex:0];
    NSString *dayNumber = [array objectAtIndex:1];
    NSDate *date = calendarMonth.dateOfFirst;
    TKUDateInformation info = [date dateInformation];
    info.day = dayNumber.intValue;

    [self setSelectedDate:[NSDate dateFromDateInformation:info]];
    if ([self.delegate respondsToSelector:@selector(calendarMonthView:dateWasSelected:)]) {
        [self.delegate calendarMonthView:self dateWasSelected:[self selectedDate]];
    }
}

#pragma mark LEFT & RIGHT BUTTON ACTIONS

- (void)leftButtonTapped
{
    [self moveCalendarMonthsDownAnimated:TRUE];
    [self selectDayInMonth];
}

- (void)rightButtonTapped
{
    [self moveCalendarMonthsUpAnimated:TRUE];
    [self selectDayInMonth];
}

- (void)selectDayInMonth
{
    TKUDateInformation info1 = [[self selectedDate] dateInformation];
    info1.hour = info1.minute = info1.second = 0;

    TKUDateInformation info2 = [self.selectedMonth dateInformation];
    info2.hour = info2.minute = info2.second = 0;

    NSInteger difference = [[NSDate dateFromDateInformation:info1] differenceInMonthsTo:[NSDate dateFromDateInformation:info2]];
    if (difference == 0) {
        [[self.deck objectAtIndex:1] selectDay:info1.day];
    }
}

- (void)drawRect:(CGRect)rect
{
    [[UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/topbar.png")] drawAtPoint:CGPointMake(0, 0)];

    [self drawDayLabels:rect];
    [self drawMonthLabel:rect];
}

- (void)drawMonthLabel:(CGRect)rect
{
    if (self.monthYear != nil) {
        CGRect r = CGRectMake(0, 8, 320, 44);
        r.size.height = 42;
        [[UIColor colorWithRed:75.0 / 255.0 green:92 / 255.0 blue:111 / 255.0 alpha:1] set];
        [self.monthYear drawInRect:r
                     withFont:[UIFont boldSystemFontOfSize:20.0]
                lineBreakMode:UILineBreakModeWordWrap
                    alignment:UITextAlignmentCenter];
    }
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

    UIFont *f = [UIFont boldSystemFontOfSize:10];
    [[UIColor darkGrayColor] set];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context,  CGSizeMake(0.0, -1.0), 0.5, [[UIColor whiteColor] CGColor]);

    int i = 0;
    for (NSString *str in days) {
        [str drawInRect:CGRectMake(i * 46, 44 - 12, 45, 10) withFont:f lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
        i++;
    }
    CGContextRestoreGState(context);
}

@end

@implementation TKUMonthGridView

- (int)daysInPreviousMonth
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:self.dateOfFirst];
    [comp setDay:1];
    [comp setMonth:comp.month - 1];
    int daysInPreviousMonth = [[gregorian dateFromComponents:comp] daysInMonth];
    return daysInPreviousMonth;
}

- (id)initWithStartDate:(NSDate *)theDate today:(NSInteger)todayDay marks:(NSArray *)marksArray
{
    if (self = [self initWithFrame:CGRectMake(0, 0, 320, 320)]) {
        [self setStartDate:theDate today:todayDay marks:marksArray];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
}

- (void)buildGrid
{
    self.dayTiles = [[NSMutableArray alloc] init];

    int position = self.weekdayOfFirst;
    int line = 0;

    int daysInPreviousMonth = [self daysInPreviousMonth];
    int daysInMonth = [self.dateOfFirst daysInMonth];
    int lead = daysInPreviousMonth - (position - 2);

    for (int i = 1; i < position; i++) {
        TKUCalendarDayView *dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectMake((i - 1) * 46 - 1, 0, 47, 45)];
        [dayView setActive:NO];
        dayView.str = [NSString stringWithFormat:@"%d", lead];
        [self addSubview:dayView];
        [self.dayTiles addObject:dayView];
        lead++;
    }

    BOOL isCurrentMonth = NO;
    if (self.todayNumber > 0) {
        isCurrentMonth = YES;
    }

    for (int i = 1; i <= daysInMonth; i++) {
        TKUCalendarDayView *dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectMake((position - 1) * 46 - 1, line * 44, 47, 45)];

        [dayView setMarked:[[self.marks objectAtIndex:i - 1] boolValue]];

        if (isCurrentMonth && i == self.todayNumber) {
            [dayView setToday:YES];
        } else {
            [dayView setToday:NO];
        }

        dayView.str = [NSString stringWithFormat:@"%d", i];

        // Set the tag as the day view
        // Will be used in order to reseet marks
        // Each day view is easily accessible using viewWithTag
        dayView.tag     = i;

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
        int counter = 1;
        for (int i = position; i < 8; i++) {
            TKUCalendarDayView *dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectMake((i - 1) * 46 - 1, line * 44, 47, 45)];
            dayView.str = [NSString stringWithFormat:@"%d", counter];
            [dayView setActive:NO];

            [self addSubview:dayView];
            [self.dayTiles addObject:dayView];
            counter++;
        }
    }

    CGRect r = self.frame;
    r.size.height = (line + 1) * 44;
    self.frame = r;

    self.lines = line;
    if (position == 1) {
        self.lines--;
    }
}

- (void)resetMarks
{
    for (NSInteger i = 1; i <= self.marks.count; i++) {
        TKUCalendarDayView *dayView = (TKUCalendarDayView *)[self viewWithTag:i];

        [dayView setMarked:[[self.marks objectAtIndex:i - 1] boolValue]];
    }
    [self setNeedsDisplay];
}

- (TKUCalendarDayView *)oldDayTile
{
    if ([self.graveYard count] > 0) {
        TKUCalendarDayView *d = [self.graveYard objectAtIndex:0];
        [self.graveYard removeObjectAtIndex:0];
        return d;
    }
    return nil;
}

- (void)build
{
    [self.graveYard addObjectsFromArray:self.dayTiles];
    self.dayTiles = [[NSMutableArray alloc] init];

    int position = self.weekdayOfFirst;
    int line = 0;

    int daysInPreviousMonth = [self daysInPreviousMonth];
    int daysInMonth = [self.dateOfFirst daysInMonth];
    int lead = daysInPreviousMonth - (position - 2);

    TKUCalendarDayView *dayView;

    for (int i = 1; i < position; i++) {
        dayView = [self oldDayTile];
        if (dayView == nil) {
            dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectZero];
        }
        dayView.frame = CGRectMake((i - 1) * 46 - 1, 0, 47, 45);
        [dayView setString:[NSString stringWithFormat:@"%d", lead] selected:NO active:NO today:NO marked:NO];

        [self addSubview:dayView];
        [self.dayTiles addObject:dayView];

        lead++;
    }

    BOOL isCurrentMonth = NO;
    if (self.todayNumber > 0) {
        isCurrentMonth = YES;
    }

    for (int i = 1; i <= daysInMonth; i++) {
        dayView = [self oldDayTile];
        if (dayView == nil) {
            dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectZero];
        }

        dayView.frame = CGRectMake((position - 1) * 46 - 1, line * 44, 47, 45);

        BOOL today = isCurrentMonth && i == self.todayNumber ? YES : NO;

        [dayView setString:[NSString stringWithFormat:@"%d", i] selected:NO active:YES today:today marked:[[self.marks objectAtIndex:i - 1] boolValue]];

        // Set the tag as the day view
        // Will be used in order to reseet marks
        // Each day view is easily accessible using viewWithTag
        dayView.tag     = i;

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
        int counter = 1;
        for (int i = position; i < 8; i++) {
            dayView = [self oldDayTile];
            if (dayView == nil) {
                dayView = [[TKUCalendarDayView alloc] initWithFrame:CGRectZero];
            }

            dayView.frame = CGRectMake((i - 1) * 46 - 1, line * 44, 47, 45);
            [dayView setString:[NSString stringWithFormat:@"%d", counter] selected:NO active:NO today:NO marked:NO];

            [self addSubview:dayView];
            [self.dayTiles addObject:dayView];
            counter++;
        }
    }

    CGRect r = self.frame;
    r.size.height = (line + 1) * 44;
    self.frame = r;

    self.lines = line;
    if (position == 1) {
        self.lines--;
    }
}

- (void)selectDay:(int)theDayNumber
{
    int i = 0;

    while (i < [self.dayTiles count]) {
        if ([[[self.dayTiles objectAtIndex:i] str] intValue] == 1) {
            break;
        }
        i++;
    }
    [self.selectedDay setSelected:NO];
    self.selectedDay = [self.dayTiles objectAtIndex:i + theDayNumber - 1];
    [[self.dayTiles objectAtIndex:i + theDayNumber - 1] setSelected:YES];

    [self bringSubviewToFront:self.selectedDay];
}

- (void)selectDayView:(UITouch *)touch
{
    CGPoint p = [touch locationInView:self];
    int index = ((int)p.y / 44) * 7 + ((int)p.x / 46);

    if (index > [self.dayTiles count]) {
        return;
    }

    TKUCalendarDayView *selected = [self.dayTiles objectAtIndex:index];

    if (![selected active]) {
        if ([selected.str intValue] > 15) {
            [self.delegate performSelector:@selector(previousMonthDayWasSelected:) withObject:selected.str];
        } else {
            [self.delegate performSelector:@selector(nextMonthDayWasSelected:) withObject:selected.str];
        }
        return;
    }

    [self.selectedDay setSelected:NO];
    [self bringSubviewToFront:selected];
    [selected setSelected:YES];
    self.selectedDay = selected;

    [self.delegate performSelector:@selector(dateWasSelected:) withObject:[NSArray arrayWithObjects:self, selected.str, nil]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    [self selectDayView:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event];
    [self selectDayView:[touches anyObject]];
}

- (void)setStartDate:(NSDate *)theDate today:(NSInteger)todayDay marks:(NSArray *)marksArray
{
    TKUDateInformation info = [theDate dateInformation];
    info.day  = 1;
    self.dateOfFirst = [NSDate dateFromDateInformation:info];

    // Calendar starting on Monday instead of Sunday (Australia, Europe against US american calendar)
    self.weekdayOfFirst = [self.dateOfFirst weekdayWithMondayFirst];
    self.todayNumber = todayDay;
    self.marks = marksArray;

    if (self.dayTiles == nil) {
        self.dayTiles = [[NSMutableArray alloc] init];
        self.graveYard = [[NSMutableArray alloc] init];
    }

    [self build];
}

@end

@implementation TKUCalendarDayView

@synthesize selected, active, today, marked, str;

- (id)initWithFrame:(CGRect)frame string:(NSString *)string selected:(BOOL)sel active:(BOOL)act today:(BOOL)tdy marked:(BOOL)mark
{
    if (self = [super initWithFrame:frame]) {
        [self setString:(NSString *)string selected:(BOOL)sel active:(BOOL)act today:(BOOL)tdy marked:(BOOL)mark];
    }
    return self;
}

- (void)setString:(NSString *)string selected:(BOOL)sel active:(BOOL)act today:(BOOL)tdy marked:(BOOL)mark
{
    str = [string copy];
    selected = sel;
    active = act;
    today = tdy;
    marked = mark;
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        active = YES;
        today = NO;
        marked = NO;
        selected = NO;
        self.opaque = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code

    UIImage *d;
    UIColor *color;

    if (!active) {
        // color = [UIColor colorWithRed:36.0/255.0 green:49/255.0 blue:64/255.0 alpha:1];
        color = [UIColor grayColor];
        d = [UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/datecell.png")];
    } else if (today && selected) {
        color = [UIColor whiteColor];
        d = [UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/todayselected.png")];
    } else if (today) {
        color = [UIColor whiteColor];
        d = [UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/today.png")];
    } else if (selected) {
        color = [UIColor whiteColor];
        d = [UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/datecellselected.png")];
    } else {
        color = [UIColor colorWithRed:75.0 / 255.0 green:92 / 255.0 blue:111 / 255.0 alpha:1];
        d = [UIImage imageFromPath:TKUBUNDLE(@"TapkuLibrary.bundle/Images/calendar/datecell.png")];
    }

    [d drawAtPoint:CGPointMake(0, 0)];

    [color set];

    [str drawInRect:CGRectInset(self.bounds, 4, 9)
           withFont:[UIFont boldSystemFontOfSize:22]
      lineBreakMode:UILineBreakModeWordWrap
          alignment:UITextAlignmentCenter];

    if (marked) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (selected || today) {
            CGContextSetRGBFillColor(context, 1, 1, 1, 1.0);
        } else {
            CGContextSetRGBFillColor(context, 75.0 / 255.0, 92 / 255.0, 111 / 255.0, 1.0);
        }

        CGContextSetLineWidth(context, 0.0);
        CGContextAddEllipseInRect(context, CGRectMake(self.frame.size.width / 2 - 2, 45 - 10, 4, 4));
        CGContextFillPath(context);
    }
}

- (void)setSelected:(BOOL)select
{
    selected = select;
    [self setNeedsDisplay];
}

- (void)setToday:(BOOL)tdy
{
    if (tdy == today) {
        return;
    }
    today = !today;
    [self setNeedsDisplay];
}

- (void)setActive:(BOOL)act
{
    if (active == act) {
        return;
    }
    active = act;
    [self setNeedsDisplay];
}

- (void)setMarked:(BOOL)mark
{
    if (marked == mark) {
        return;
    }
    marked = !marked;
    [self setNeedsDisplay];
}

@end