

#import <Foundation/Foundation.h>
#import "NSExpressionWithErrorHandler.h"
@implementation NSExpressionWithErrorHandler
@synthesize format;
@synthesize errorOfFormat;


- (int)sumOfA: (int)a andB: (int)b {
	return a + b;
}

- (instancetype)initWithFormat:(NSString *)frmt {
    self = [super init];
    if (self) {
        self.format = frmt;
        self.errorOfFormat = @"No error";
    }
    @try {
		
        NSExpression* expression2 = [NSExpression expressionWithFormat:frmt];
        id value = [expression2 expressionValueWithObject:nil context:nil];
        
    } @catch (NSException *exception) {
//        NSLog(@"Error");
        
        self.errorOfFormat = [NSString stringWithFormat:@"%@", [exception description]];
        
        
    } @finally {
//        NSLog(@"Finally");
//        NSLog(self.errorOfFormat);
    }
    return self;
}

- (NSString *)getError {
    return self.errorOfFormat;
}

- (NSPredicate *)getPreficate {
    @try {
        NSExpression* e = [NSExpression expressionWithFormat:[self format]];
        return [e predicate];
        
    } @catch (NSException *err) {
//        NSLog(@"Pula");
    } @finally {
//        NSLog(@"F");
    }
}

- (NSNumber *)getResultWithSubstitiutionVariables: (NSDictionary<NSString *, NSNumber *> *)subVars {
    @try {
        NSExpression* e = [NSExpression expressionWithFormat:[self format]];
        id val = [e expressionValueWithObject:subVars context:nil];
        return val;
        
    } @catch (NSException *err) {
//        NSLog(@"Pula");
    } @finally {
//        NSLog(@"F");
    }
    return nil;
}



@end

@interface NSNumber ( SinCosine )

- (NSNumber *)sin;
- (NSNumber *)cos;
- (NSNumber *)factorial;

@end

@implementation NSNumber ( SinCosine )

- (NSNumber *)sin {
    double val = self.doubleValue;
    double s = sin(val);
    return [NSNumber numberWithDouble:s];
}

- (NSNumber *)cos {
    double val = self.doubleValue;
    double s = cos(val);
	
    return [NSNumber numberWithDouble:s];
}

- (NSNumber *)factorial {
    int val = self.intValue;
    long long int res = 1;
    for(int i = 1; i <= val; i ++) {
        res *= i;
    }
    return [NSNumber numberWithLongLong:res];
    
}

@end
