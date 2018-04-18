#import <Foundation/Foundation.h>

/**
 NSDictionary + KeyCaseInsensitive
 */
@interface NSDictionary(KeyCaseInsensitive)
-(__nullable id)objectForKey_CaseInsensitive:(__nullable id)aKey;
@property(nonatomic,copy,readonly,getter=description_pretty_json) NSString* __nullable description_pretty_json;
@end

@interface NSArray(description_pretty_json)
@property(nonatomic,copy,readonly,getter=description_pretty_json) NSString* __nullable description_pretty_json;
@end
