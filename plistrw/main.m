//
//  main.m
//  plistrw
//
//  Created by Xnollis on 2018/4/18.
//  Copyright © 2018 Xnollis. All rights reserved.
//
#import "PListVistPathRecord.h"
#import "NSDictionary+KeyCaseInsensitive.h"
#import "apis.h"
/////////////////////////////////////////////
/// Customize NSLog()
#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif
/////////////////////////////////////////////
int main(int argc, const char * argv[])
{
    if(argc==2&&strcmp(argv[1],"--plist_template")==0)
    {
        fprintf(stdout,"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict/></plist>");
        return 0;
    }
    if(argc<3)
    {
        fprintf(stderr,"Invalid params.\n");
        print_usage();
        return -1;
    }
    @autoreleasepool
    {
        int iRetCode=-1;
        @try
        {
            iRetCode=inner_main(argc, argv);
        }
        @catch(NSException *ex)
        {
            fprintf(stderr,"%s\n",ex.reason.UTF8String);
            iRetCode=getExceptionCodeFromExcp(ex);
        }
        return iRetCode;
    }
}
/////////////////////////////////////////////
/**
 Analyze a string with format "[3][4][5][6]", and the put indexs value into an Array

 @param strIndexOrgQuote the string to be analyzed
 @return the Index Array
 */
NSMutableArray *getIndexValueArray(NSString *strIndexOrgQuote)
{//strIndexOrgQuote是有如下格式的下标字符串 [3][4][5][6]
    strIndexOrgQuote=[strIndexOrgQuote stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(strIndexOrgQuote.length<=0)return nil;
    if([strIndexOrgQuote rangeOfString:@"["].location==NSNotFound||
       [strIndexOrgQuote rangeOfString:@"]"].location==NSNotFound)
        return nil;
    NSString* strww=[strIndexOrgQuote stringByReplacingOccurrencesOfString:@"[]" withString:@"[0]"];
    strww=[strww stringByReplacingOccurrencesOfString:@"]" withString:@" "];
    strww=[strww stringByReplacingOccurrencesOfString:@"[" withString:@" "];
    strww=[strww stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *aarr=[strww componentsSeparatedByString:@" "];
    if(aarr.count<=0)return nil;
    NSMutableArray *rer=[NSMutableArray new];
    for (NSString * s in aarr)
    {
        NSString* s0=[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(s0.length<=0)continue;
        [rer addObject:@(s0.intValue)];
    }
    return rer;
}
/**
 pass in an object , then according to the Index array, fetch the item from the parent object(array) at one time.
 this function can deal with multiply level of indexs, which like this "arr[3][4][5][6]".
 then, use the param "parentObject_in_out" to return the last level parent object of child item we finally got.

 @param parentObject_in_out the parent object(array) to get item from. it also can be used to return new parent object
 @param arrIndexs the index array, which from getIndexValueArray() function.
 @return child item object
 */
id getChildObjFromParentArray(id *parentObject_in_out,NSArray* arrIndexs)
{
    id parentObject=*parentObject_in_out;
    Class arrayCLASS=[NSArray class];
    if ([parentObject isKindOfClass:arrayCLASS])
    {
        id obj1;
        NSArray *parArray=(NSArray*)parentObject,*paa=arrIndexs;
        @try
        {
            NSUInteger i,j=paa.count;
            for (i=0;i<j;++i)
            {
                NSNumber *nu=paa[i];
                obj1=parArray[nu.unsignedIntegerValue];
                if(i<j-1)
                {
                    NSLog(@"");
                    if([obj1 isKindOfClass:arrayCLASS])
                    {
                        parArray=obj1;
                    }
                    else return nil;
                }
            }
            *parentObject_in_out=parArray;
            return obj1;
        }
        @catch(NSException *e)
        {
            return nil;
        }
    }
    return nil;
}
/**
 get child object from parent object. this function can deal with NSDictionary and NSArray.

 @param parentObject_in_out the parent object to get item from. it also can be used to return new parent object
 @param strKeyPathName the "relevant" KeyPathName to child item from current parent object
 @param piLastIndexInParentArray the last IndexInParentArray
 @return child item object
 */
id getChildObjFromParentObj(id *parentObject_in_out,NSString* strKeyPathName,NSUInteger *piLastIndexInParentArray)
{
    id parentObject=*parentObject_in_out;
    if(parentObject==nil||strKeyPathName.length<=0)return nil;
    NSString *strKeyName=strKeyPathName;
    NSRange rg;
    rg=[strKeyPathName rangeOfString:@"["];
    BOOL bHaveArrayIndex=(rg.location!=NSNotFound);
    if(bHaveArrayIndex)
        strKeyName=[strKeyPathName substringToIndex:rg.location];
    if ([parentObject isKindOfClass:[NSDictionary class]])
    {
        if (bHaveArrayIndex)
        {
            *parentObject_in_out=[(NSDictionary*)parentObject objectForKey_CaseInsensitive:strKeyName];
            NSArray *arr=getIndexValueArray([strKeyPathName substringFromIndex:rg.location]);
            *piLastIndexInParentArray=[arr.lastObject unsignedIntegerValue];
            return getChildObjFromParentArray(parentObject_in_out,arr);
        }
        else
        {
            return [(NSDictionary*)parentObject objectForKey_CaseInsensitive:strKeyName];
        }
    }
    return nil;
}
/**
 Analyze the command line param string, convert it to an Obj-C type object
 supported value string format:
 1)int , eg 345 .
 2)float, eg 3.45 .
 3)string, eg "aaabbb" .
 4)bool, eg BOOL_TRUE/BOOL_FALSE.
 5)hex-bin, eg <ff33ee88aabb>.
 6)json string, eg {"aa":"bb","cc":[11,22,33]}, aka complex object
 @param newValueFromCommandLine command line param string from main()
 @return converted Objc object
 */
id getObjectOfWrite(const char* newValueFromCommandLine)
{
    id nv;
    NSString* str=[[NSString stringWithUTF8String:newValueFromCommandLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(str.length<=0)return nil;
    if(isPureInt(str))
    {
        nv=@(str.longLongValue);
    }
    else if (isPureFloat(str))
    {
        nv=@(str.doubleValue);
    }
    else if(str.length>=2&&str.UTF8String[0]=='<'&&str.UTF8String[str.length-1]=='>')
    {
        NSString *str1=[[str substringWithRange:NSMakeRange(1, str.length-2)] lowercaseString];
        if(str1.length%2!=0)return nil;//16进制值的字符串,其长度必须是2的整数倍
        char buf[3],*dataBuf,*dataBufPtr,*s0,*str2=(char*)str1.UTF8String;
        unsigned int v;
        s0=str2;
        buf[2]=0;
        dataBufPtr=dataBuf=malloc(str1.length/2);
        while (*s0)
        {
            buf[0]=s0[0];
            buf[1]=s0[1];
            sscanf(buf, "%02x",&v);
            *dataBufPtr++=(char)v;
            s0+=2;
        }
        nv=[NSData dataWithBytes:dataBuf length:str1.length/2];
        free(dataBuf);
    }
    else if(str.length>5&&[[str substringToIndex:5] compare:@"bool_" options:NSCaseInsensitiveSearch]==NSOrderedSame)
    {
        NSString *str2=[str substringFromIndex:5];
        if ([str2 isEqualToString:@"1"]||[str2 compare:@"true" options:NSCaseInsensitiveSearch]==NSOrderedSame)
        {
            nv=@(YES);
        }
        else
        {
            nv=@(NO);
        }
    }
    else
    {
        //看看是不是json字符串
        NSError *jsonParseError=0;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:newValueFromCommandLine length:strlen(newValueFromCommandLine)] options:kNilOptions error:&jsonParseError];
        if (json&&jsonParseError==nil)
            nv=json;
        else
            nv=str;
    }
    return nv;
}
/////////////////////////////////////////////
int inner_main(int argc, const char * argv[])
{
    return 0;
}
