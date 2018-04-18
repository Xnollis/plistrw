//
//  NSDictionary+KeyCaseInsensitive.m
//  plistrw
//
//  Created by Xnollis on 2018/4/18.
//  Copyright © 2018 Xnollis. All rights reserved.
//
#import "NSDictionary+KeyCaseInsensitive.h"

@implementation NSDictionary(KeyCaseInsensitive)
-(id)objectForKey_CaseInsensitive:(id)aKey
{
    if(aKey==nil)return nil;
    if ([aKey isKindOfClass:[NSString class]]==NO)
        return [self objectForKey:aKey];
    
    id res=[self objectForKey:aKey];
    if(res!=nil)return res;
    
    NSEnumerator *enumerator = [self keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])!=nil)
    {
        if ([key isKindOfClass:[NSString class]])
        {
            if ([((NSString*)key) compare:(NSString*)aKey options:NSCaseInsensitiveSearch]==NSOrderedSame)
            {
                return [self objectForKey:key];
            }
        }
    }
    return nil;
}
@end
