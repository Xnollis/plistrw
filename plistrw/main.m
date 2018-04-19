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
void test_main(void);
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
    BOOL bNeedQuiet=IsEnvSettingEnabled("PLISTRW_QUIET");
    BOOL bIsRunTestMode=IsEnvSettingEnabled("PLISTRW_RUN_TEST");
    
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
        if (bIsRunTestMode)
        {
            test_main();
            return 0;
        }
        
        int iRetCode=-1;
        @try
        {
            iRetCode=inner_main(argc, argv);
        }
        @catch(NSException *ex)
        {
            if(bNeedQuiet==NO)
                fprintf(stderr,"%s",ex.reason.UTF8String);
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
    NSMutableDictionary *rootDictionary=[[NSMutableDictionary alloc]initWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
    NSMutableArray *rootArray=nil;
    if (rootDictionary==nil)
    {
        rootArray=[[NSMutableArray alloc]initWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
        if (rootArray==nil)
        {
            RaiseExceptionWithCodeAndReason(1, [NSString stringWithFormat:@"Bad or not existed plist file:\n%s",argv[1]]);//exit point
        }
    }
    //--------------------------------------------------------
    Class arrayCLASS=[NSArray class];
    Class dictCLASS=[NSDictionary class];
    NSString *strKeyPath=[NSString stringWithUTF8String:argv[2]];//get whole key path
    NSArray *arrKeyPath=[strKeyPath componentsSeparatedByString:@"/"];
    
    NSString *key1;
    NSUInteger i=0,j=arrKeyPath.count;
    
    BOOL bIsWriteMode=(argc>=4);
    BOOL bIsRemoveMode=(argc==4&&argv[3][0]=='-');
    
    NSMutableArray *arrOfVisitedRecord=[NSMutableArray new];
    
    for (id objCurrent,objParent=rootDictionary?rootDictionary:rootArray; i<j; ++i)
    {
        key1=arrKeyPath[i];
        key1=[key1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //NSLog(@"访问节点：%@",key1);
        
        NSUInteger iLPA=0;
        PListVistPathRecord *record=[PListVistPathRecord new];
        BOOL bIsArrayAddNewMode=([key1 rangeOfString:@"[]"].location!=NSNotFound);
        if(bIsArrayAddNewMode)
        {
            NSString *key1_tmp=[key1 stringByReplacingOccurrencesOfString:@"[]" withString:@""];
            id tmpPrOBJ=objParent;
            NSUInteger iLPAt=0;
            objCurrent=getChildObjFromParentObj(&tmpPrOBJ,key1_tmp,&iLPAt);
            if(objCurrent&&[objCurrent isKindOfClass:arrayCLASS]==NO)
                RaiseExceptionWithCodeAndReason(2, [NSString stringWithFormat:@"Error: Path \"%@\" is not an ARRAY object! Can't add an array item!\n",key1_tmp]);//exit point
        }
        objCurrent=getChildObjFromParentObj(&objParent,key1,&iLPA);
        record.parentNode=objParent;
        record.currentName=key1;
        record.currentValue=objCurrent;
        if(objCurrent==nil)iLPA=NSNotFound;
        record.iLastIndexInParentArray=iLPA;
        
        //NSLog(@"得到的节点类型为：%@",(objCurrent==nil?@"(无)":NSStringFromClass([objCurrent class])));
        
        [arrOfVisitedRecord addObject:record];
        if(objCurrent==nil)
        {//最后一个path是可以为空的。除此之外都是非法情形
            if (!bIsWriteMode||i<j-1||bIsRemoveMode)
            {
                RaiseExceptionWithCodeAndReason(2, [NSString stringWithFormat:@"Error: Path \"%@\" does not exist!\n",key1]);//exit point
            }
            break;
        }
        objParent=objCurrent;
    }
    if (bIsWriteMode)
    {
        id newValueToWrite=getObjectOfWrite(argv[3]);
        PListVistPathRecord *recordLast=(PListVistPathRecord*)arrOfVisitedRecord.lastObject;
    DO_Write_AGAIN:
        if([recordLast.parentNode isKindOfClass:arrayCLASS]&&recordLast.iLastIndexInParentArray!=NSNotFound)
        {
            BOOL bIsArrayAddNewMode=([recordLast.currentName rangeOfString:@"[]"].location!=NSNotFound);
            NSMutableArray* aa=(NSMutableArray*)recordLast.parentNode;
            if(bIsArrayAddNewMode)
            {
                [aa addObject:newValueToWrite];
            }
            else if(bIsRemoveMode)
            {
                if(aa.count>recordLast.iLastIndexInParentArray)
                    [aa removeObjectAtIndex:recordLast.iLastIndexInParentArray];
                else
                {
                    RaiseExceptionWithCodeAndReason(3, [NSString stringWithFormat:@"Error: Path \"%@\" index %d is out of the Array bound!\n",
                                                        recordLast.currentName,(int)recordLast.iLastIndexInParentArray]);//exit point
                }
            }
            else
            {
                [aa setObject:newValueToWrite atIndexedSubscript:recordLast.iLastIndexInParentArray];
            }
        }
        else if([recordLast.parentNode isKindOfClass:dictCLASS])
        {
            NSMutableDictionary* aa=(NSMutableDictionary*)recordLast.parentNode;
            if(bIsRemoveMode)
            {
                [aa removeObjectForKey:recordLast.currentName];
            }
            else
            {
                [aa setObject:newValueToWrite forKey:recordLast.currentName];
            }
        }
        else
        {//向上退一级
            PListVistPathRecord *record_Before_Last;
            record_Before_Last=[PListVistPathRecord new];
            
            if([recordLast.currentName rangeOfString:@"[]"].location!=NSNotFound)
                newValueToWrite=@[newValueToWrite];
            else
                newValueToWrite=@{recordLast.currentName:newValueToWrite};
            
            NSUInteger nowParentIndex=[arrOfVisitedRecord indexOfObject:recordLast inRange:NSMakeRange(0, arrOfVisitedRecord.count)];
            if (nowParentIndex>0)
            {
                --nowParentIndex;
                PListVistPathRecord *rr=arrOfVisitedRecord[nowParentIndex];
                record_Before_Last.parentNode=rr.parentNode;
                record_Before_Last.iLastIndexInParentArray=rr.iLastIndexInParentArray;
                record_Before_Last.currentName=([rr.currentName rangeOfString:@"]"].location==NSNotFound)?rr.currentName:recordLast.currentName;
            }
            else
            {
                record_Before_Last.parentNode=rootArray?rootArray:rootDictionary;
                record_Before_Last.iLastIndexInParentArray=NSNotFound;
                record_Before_Last.currentName=recordLast.currentName;
            }
            recordLast=record_Before_Last;
            goto DO_Write_AGAIN;
        }
        BOOL bWriteOK=NO;
        if(rootDictionary)
            bWriteOK=[rootDictionary writeToFile:[NSString stringWithUTF8String:argv[1]] atomically:YES];
        if(rootArray)
            bWriteOK=[rootArray writeToFile:[NSString stringWithUTF8String:argv[1]] atomically:YES];
        if (!bWriteOK)
        {
            RaiseExceptionWithCodeAndReason(4, [NSString stringWithFormat:@"Error: Write to File \"%s\" Fail!\n",argv[1]]);//exit point
        }
    }
    else
    {
        //将得到的对象值，格式化为字符串
        id ob2=((PListVistPathRecord*)arrOfVisitedRecord.lastObject).currentValue;
        if ([ob2 respondsToSelector:@selector(description_pretty_json)])
        {
            key1=[ob2 performSelector:@selector(description_pretty_json)];
        }
        else
        {
            key1=[NSString stringWithFormat:@"%@",ob2];
        }
        fprintf(stdout,"%s",key1.UTF8String);
    }
    return 0;
}
typedef const char * argvtype[5];
void test_main()
{
    int iRet;
    const char * plistfile="/tmp/plistrw_t1.plist";
    const char * argv_param_0="";
    argvtype argv_all[]={
        {argv_param_0,plistfile,"a","a obj"},
        {argv_param_0,plistfile,"a/b","b obj under a"},
        {argv_param_0,plistfile,"a/b","a changed b obj under a"},
        {argv_param_0,plistfile,"a/b/c/d","a ABCD obj"}, //should fail
        {argv_param_0,plistfile,"a/b/dic1","{\"inner1\":\"11111\",\"inner_array\":[23,45,67,\"fef\"],\"inner2\":\"aaaa222aa\"}"},
        {argv_param_0,plistfile,"a/b/c","a CCCC obj"},
        {argv_param_0,plistfile,"a/b/booltype","Bool_True"},
        {argv_param_0,plistfile,"a/b/hex-value","<1a2b3c4dfeaaff>"},
        {argv_param_0,plistfile,"a/d","[23,45,67.789]"},
        {argv_param_0,plistfile,"a/d[2]","[\"123\",145.252,167]"},
        {argv_param_0,plistfile,"a/d[2][0]","<9988991a2b3c4dfeaaff>"},
        {argv_param_0,plistfile,"a/d[2][3]/g","g2222"},//should fail
        {argv_param_0,plistfile,"a/d[2][2]/g","g2222"},
        {argv_param_0,plistfile,"a/d[2][2][]","arr22"},//should fail
        {argv_param_0,plistfile,"a/d[2][2]","[11,33.76,55]"},//change the Object Type from Dict to Array
        {argv_param_0,plistfile,"a/d[2][2][]","arr22"},
        {argv_param_0,plistfile,"a/d[2][2][]","-"},//should success. "[]"(add array item operation) priority is higher than "-"(remove operation)
        {argv_param_0,plistfile,"a/d[2][]","arr11"},
        {argv_param_0,plistfile,"a/d[2][]","[\"sub level item\",55.5,66.6,77.7,100]"},
        {argv_param_0,plistfile,"a/d[2][3]/g","-"},//should fail
        {argv_param_0,plistfile,"a/d[2][2]/g","-"},//should fail
        {argv_param_0,plistfile,"a/d[2]/g","-"},//should fail
        {argv_param_0,plistfile,"a/d[0]","-"},
        {argv_param_0,plistfile,"a/d[0]","-"},
        {argv_param_0,plistfile,"a/d[0]","-"},
        {argv_param_0,plistfile,"a/b/dic1/inner_array[0]","-"},
        {argv_param_0,plistfile,"a/b/dic1/inner_array[0]","-"},
        {argv_param_0,plistfile,"a/b/dic1/inner_array[0]","-"},
        {argv_param_0,plistfile,"a/b/dic1/inner_array[0]","-"},
        {argv_param_0,plistfile,"a/b/dic1/inner_array[0]","-"},//should fail
        {argv_param_0,plistfile,"a/b/dic1/inner_array","-"},
        {argv_param_0,plistfile,"a/b/dic1/inner1","-"},
        {argv_param_0,plistfile,"a/b/dic1/inner2","-"},
        {argv_param_0,plistfile,"a/b/dic1"},
    };
    int test_result_array[]={
        0,
        0,
        0,
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        0,
        2,
        0,
        0,
        0,
        0,
        0,
        2,
        2,
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2,
        0,
        0,
        0,
        0};
    size_t i,k,n,j=sizeof(argv_all)/sizeof(argvtype);
    NSMutableArray *arr=[NSMutableArray new];
    for (i=0; i<j; ++i)
    {
        for (k=0,n=0; n<5; ++n)
        {
            if(argv_all[i][n]!=NULL)
                ++k;
        }
        @try
        {
            NSString *str1=[NSString stringWithFormat:@"\n===================\nTest target params:\n1:%s\n2:%s\n3:%s\n",argv_all[i][1],argv_all[i][2],(argv_all[i][3]==NULL?"":argv_all[i][3])];
            fprintf(stderr,"%s",str1.UTF8String);
            
            iRet=inner_main((int)k, argv_all[i]);
        }
        @catch(NSException *ex)
        {
            fprintf(stderr,"%s",ex.reason.UTF8String);
            iRet=getExceptionCodeFromExcp(ex);
        }
        [arr addObject:@(iRet)];
        fprintf(stderr,"%s\n",[NSString stringWithFormat:@">>>>>>>Test result:%@%@\n--------------------",
                               (iRet==test_result_array[i]?@"Pass!!":@"Fail!!"),
                               (iRet==0?@"":@"(should got an error)")
                               ].UTF8String);
    }
    //NSLog(@"%@",arr);
}
