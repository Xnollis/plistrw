#import <Foundation/Foundation.h>
/**
 Record the Visit Info of current Node
 */
@interface PListVistPathRecord:NSObject
@property(nonatomic,weak) id parentNode;//必须是一个字典或者NSArray
@property(nonatomic,weak) NSString* currentName;//当前节点的名字，包含序列号
@property(nonatomic,weak) id currentValue;//当前节点的值
@property(nonatomic,assign) NSUInteger iLastIndexInParentArray;
@end
