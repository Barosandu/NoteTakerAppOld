//
//  EvaluatorC.h
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 18.05.2022.
//

#ifndef EvaluatorC_h
#define EvaluatorC_h

@interface ObjCResult : NSObject

@property(strong, nonatomic) NSNumber * value;
@property(nonatomic) BOOL hasError;

+ (instancetype)initWithValue:(NSNumber *)val hasError:(BOOL)hasErr;
+ (instancetype)initWithCValue:(float)val hasErrorC:(bool)hasErr;

- (float)floatValue;
- (BOOL)isNil;
- (BOOL)isValid;

@end

@interface ExpressionEvaluator : NSObject

@property(strong, nonatomic) NSString * expressionValue;

+ (instancetype)initWithExpressionValue: (NSString *)expressionValue;
- (ObjCResult *)solveExpressionForXEqualTo:(NSNumber *)x;


@end




#endif /* EvaluatorC_h */
