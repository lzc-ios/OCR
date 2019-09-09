//
//  NSDictionary+LFAccess.m
//  LFMultipleLiveness
//
//  Copyright (c) 2017-2018 LINKFACE Corporation. All rights reserved.
//

#import "NSObject+LFAccess.h"

@implementation NSObject (LFAccess)

- (id)objectNotNullForKey:(NSString *)key {
    
    if (![self isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *dicSelf = (NSDictionary *)self;
    
    for (NSString *strKey in [dicSelf allKeys]) {
        if ([strKey isEqualToString:key]) {
            id object = [dicSelf objectForKey:key];
            if ([object isKindOfClass:[NSNull class]]) {
                return nil;
            } else {
                return object;
            }
        }
    }
    return nil;
}

@end
