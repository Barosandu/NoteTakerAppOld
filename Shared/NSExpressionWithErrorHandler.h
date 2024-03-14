//
//  NSExpressionWithErrorHandler.h
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 23.04.2022.
//

#ifndef NSExpressionWithErrorHandler_h
#define NSExpressionWithErrorHandler_h

#import <Foundation/Foundation.h>
@interface NSExpressionWithErrorHandler : NSObject

@property(strong, nonatomic) NSString * format;
@property(strong, nonatomic) NSString * errorOfFormat;

- (instancetype)initWithFormat:(NSString *)frmt;
- (NSString *)getError;
- (NSPredicate *)getPreficate;
- (NSNumber *)getResultWithSubstitiutionVariables: (NSDictionary<NSString *, NSNumber *> *)subVars;

@end

#endif /* NSExpressionWithErrorHandler_h */
