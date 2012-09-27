//
//  NSDateAdditions.m
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
#import "NSDate+TKUAdditions.h"

@implementation NSDate (TKUAdditions)

- (TKUDateInformation)dateInformation
{
    TKUDateInformation info;

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSMonthCalendarUnit | NSMinuteCalendarUnit | NSYearCalendarUnit |
                                                    NSDayCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit)
                                          fromDate:self];
    info.day = [comp day];
    info.month = [comp month];
    info.year = [comp year];

    info.hour = [comp hour];
    info.minute = [comp minute];
    info.second = [comp second];

    return info;
}

+ (NSDate *)dateFromDateInformation:(TKUDateInformation)info
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:[NSDate date]];

    [comp setDay:info.day];
    [comp setMonth:info.month];
    [comp setYear:info.year];
    [comp setHour:info.hour];
    [comp setMinute:info.minute];
    [comp setSecond:info.second];

    return [gregorian dateFromComponents:comp];
}

- (NSString *)tk_month
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM"];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)tk_year
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy"];
    return [dateFormatter stringFromDate:self];
}

- (int)daysInMonth
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:self];
    [comp setDay:0];
    [comp setMonth:comp.month + 1];

    int days = [[gregorian components:NSDayCalendarUnit fromDate:[gregorian dateFromComponents:comp]] day];

    return days;
}

+ (NSDate *)firstOfCurrentMonth
{
    NSDate *day = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:day];
    [comp setDay:1];
    return [gregorian dateFromComponents:comp];
}

+ (NSDate *)lastOfCurrentMonth
{
    NSDate *day = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:day];
    [comp setDay:0];
    [comp setMonth:comp.month + 1];
    return [gregorian dateFromComponents:comp];
}

- (NSDate *)timelessDate
{
    NSDate *day = self;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:day];
    return [gregorian dateFromComponents:comp];
}

- (NSDate *)monthlessDate
{
    NSDate *day = self;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:day];
    return [gregorian dateFromComponents:comp];
}

- (NSDate *)firstOfCurrentMonthForDate
{
    NSDate *day = self;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:day];
    [comp setDay:1];
    return [gregorian dateFromComponents:comp];
}

- (NSDate *)firstOfNextMonthForDate
{
    NSDate *day = self;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:day];
    [comp setDay:1];
    [comp setMonth:comp.month + 1];
    return [gregorian dateFromComponents:comp];
}

- (NSNumber *)dayNumber
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d"];
    return [NSNumber numberWithInt:[[dateFormatter stringFromDate:self] intValue]];
}

- (NSString *)hourString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h a"];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)monthString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM"];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)yearString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy"];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)monthYearString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM yyyy"];
    return [dateFormatter stringFromDate:self];
}

- (int)weekday
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSWeekdayCalendarUnit) fromDate:self];
    int weekday = [comps weekday];
    return weekday;
}

// Calendar starting on Monday instead of Sunday (Australia, Europe against US american calendar)
- (int)weekdayWithMondayFirst
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSWeekdayCalendarUnit) fromDate:self];
    int weekday = [comps weekday];

    CFCalendarRef currentCalendar = CFCalendarCopyCurrent();
    if (CFCalendarGetFirstWeekday(currentCalendar) == 2) {
        weekday -= 1;
        if (weekday == 0) {
            weekday = 7;
        }
    }
    CFRelease(currentCalendar);

    return weekday;
}

- (int)differenceInDaysTo:(NSDate *)toDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDateComponents *components = [gregorian components:NSDayCalendarUnit
                                                fromDate:self
                                                  toDate:toDate
                                                 options:0];
    NSInteger days = [components day];
    return days;
}

- (int)differenceInMonthsTo:(NSDate *)toDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDateComponents *components = [gregorian components:NSMonthCalendarUnit
                                                fromDate:[self monthlessDate]
                                                  toDate:[toDate monthlessDate]
                                                 options:0];
    NSInteger months = [components month];
    return months;
}

- (BOOL)isSameDay:(NSDate *)anotherDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components1 = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
    NSDateComponents *components2 = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:anotherDate];
    return ([components1 year] == [components2 year] && [components1 month] == [components2 month] && [components1 day] == [components2 day]);
}

- (BOOL)isToday
{
    return [self isSameDay:[NSDate date]];
}

@end
