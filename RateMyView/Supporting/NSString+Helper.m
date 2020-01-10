//
//  NSString+Helper.m
//  RateMyView
//
//  Created by Daniel Anderton on 17/09/2013.
//  Copyright (c) 2013 3 Equals. All rights reserved.
//

#import "NSString+Helper.h"

@implementation NSString (Helper)

+(NSString*)nonNullString:(id)object
{
    if([object isKindOfClass:[NSNull class]])
    {
        return @"";
    }
    
    if([object isKindOfClass:[NSString class]])
    {
        return (NSString*)object;
    }
    
    return @"";
}

@end
