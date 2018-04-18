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
int inner_main(int argc, const char * argv[])
{
    return 0;
}
