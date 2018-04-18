//
//  NSDictionary+KeyCaseInsensitive.m
//  plistrw
//
//  Created by Xnollis on 2018/4/18.
//  Copyright © 2018 Xnollis. All rights reserved.
//
#import "NSDictionary+KeyCaseInsensitive.h"

NSString *get_DescriptionOfObj(id obj);

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
-(NSString*)description_pretty_json
{
    return get_DescriptionOfObj(self);
}
@end

@implementation NSArray(description_pretty_json)
-(NSString*)description_pretty_json
{
    return get_DescriptionOfObj(self);
}
@end
NSString *get_DescriptionOfObj(id obj)
{
    BOOL b=[NSJSONSerialization isValidJSONObject:obj];
    if(b)
    {
        NSData *data=[NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:nil];
        if (data&&data.length>0)
        {
            NSString *s1=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            return [s1 stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        }
    }
    return [obj description];
}
