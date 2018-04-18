#import <Foundation/Foundation.h>

int inner_main(int argc, const char * argv[]);
/**
 Print Usage Info
 */
void print_usage(void);
/**
 determine if a NSString presents a Int type value

 @param string the string to be checked
 @return YES if the string can be convert to a pure Int value.
 */
BOOL isPureInt(NSString* string);
/**
 determine if a NSString presents a Float type value
 
 @param string the string to be checked
 @return YES if the string can be convert to a pure Float value.
 */
BOOL isPureFloat(NSString* string);
/**
 create a NSException object to throw

 @param exceptCode the customized exception code to carry with
 @param reason the Reason String
 @return a NSException object
 */
NSException* exceptionWithCodeAndReason(int exceptCode,NSString *reason);
/**
 get Exception code from the NSException object which created by exceptionWithCodeAndReason()

 @param excp the NSException object to get code from
 @return Exception Code
 */
int getExceptionCodeFromExcp(NSException *excp);
