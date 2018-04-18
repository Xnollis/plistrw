//
//  apis.m
//  plistrw
//
//  Created by Xnollis on 2018/4/18.
//  Copyright © 2018 Xnollis. All rights reserved.
//
#import "apis.h"
/**
 Print Usage Info
 */
void print_usage()
{
    fprintf(stderr,"Usage:\n  plistrw <PList_file> <Key1[n1]/Key2[n2]...> [NewValue] [-]\n\
Read Value Example:\n  plistrw a.plist objkey1/objkey2/obj_array[3]/key3\n\
Write Value Example:\n  Overwirte/AddNewValue to a Dictionary Item:\n    plistrw a.plist objkey1/objkey2 another_new_value\n\
  Overwirte existing item value in an Array:\n    plistrw a.plist uplevel_key_n/obj_arrayname[item_index1][....][item_index_n] another_new_value\n\
  Append New Item with new value to an Array:\n    plistrw a.plist uplevel_key_n/obj_arrayname[] another_new_value\n\
  Create an Array Object and set it as a subitem:\n    Use a json string as the <NewValue>, just like this:\n\
    plistrw a.plist uplevel_key_n/obj_arrayname \"[123,145,167]\"\n\
  Set item value as a BOOL type value:\n    plistrw a.plist uplevel_key_n/obj_name BOOL_TRUE|BOOL_FALSE\n\
  Set item value with Binary bytes value:\n    plistrw a.plist uplevel_key_n/obj_name <7C8D9EF1A3> (\"<>\"is required and length is 2n Bytes)\n\
  Remove a Dictrionary or an Array Item:\n    By using \"-\" as the last param , an specific item could be removed:\n\
    plistrw a.plist uplevel_key_n/obj_itemname -\n\
    plistrw a.plist uplevel_key_n/obj_arrayname[item_index_n] -\n\
  Skills:\n    Use json string as the <NewValue> param to create/set a complex value at one time:\n\
      plistrw a.plist uplevel_key_n/obj_name \"{\\\"key1\\\":\\\"obj1\\\",\\\"key2\\\":{\\\"subkey1\\\":\\\"subobj1\\\"},\\\"array_obj1\\\":[1234,1456,1678]}\"\n\
    Use \"--plist_template\" as the only one param to print a plist file template.\n\
Copyright Jin Xin, 2018, ShangHai.\n");
}
BOOL isPureInt(NSString* string)
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}
BOOL isPureFloat(NSString* string)
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    double val;
    return[scan scanDouble:&val] && [scan isAtEnd];
}
NSException* exceptionWithCodeAndReason(int exceptCode,NSString *reason)
{
    return [NSException exceptionWithName:@"plistrw_ex" reason:(reason==nil?@"":reason) userInfo:@{@"code":@(exceptCode)}];
}
void RaiseExceptionWithCodeAndReason(int exceptCode,NSString *reason)
{
    NSException *e=exceptionWithCodeAndReason(exceptCode, reason);
    if(e) [e raise];
}
int getExceptionCodeFromExcp(NSException *excp)
{
    NSDictionary *uInfo=excp.userInfo;
    if(!uInfo)return -1;
    NSNumber *n=uInfo[@"code"];
    if(!n)return -1;
    return n.intValue;
}
