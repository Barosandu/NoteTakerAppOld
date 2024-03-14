//
//  Shaders.metal
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 27.04.2022.
//

#include <metal_stdlib>
#define EPSILON 0.001

#define SIN "sin"
#define COS "cos"
#define TAN "tan"
#define COT "cot"
#define LN "ln"
#define SQRT "sqrt"
#define ABS "abs"

#define MAX 50
#define MA20 6

#define MAXDELTA 10000


using namespace metal;


struct Result {
    float number;
    bool hasError = false;
    Result(float n, bool e) {
        this->number = n;
        this->hasError = e;
    };
    
};
int isDigit(char c){
    if('0' <=c && c<='9'){
        return 1;
    }
    return 0;
}
int isDigitOrPoint(char c){
    if(isDigit(c) || c=='.'){
        return 1;
    }
    return 0;
}
int isOperator(char c){
    if(c=='*' || c=='+' || c=='-' || c=='/' || c=='^'){
        return 1;
    }
    return 0;
}
int isParanthesis(char c) {
    if(c=='(' || c==')'){
        return 1;
    }
    return 0;
}
int isLetter(char c){
    if('a' <= c && 'z'>= c){
        return 1;
    }
    return 0;
}
/**Function that check the identity of a function 'string' (d.b whether it is SIN or COS etc)*/
int isSIN(char fct[MAX], int fctlen){
    for(int it=0;it<fctlen;++it){
        if(fct[it] != SIN[it]){
            return 0;
        }
    }
    return 1;
}
int isCOS(char fct[MAX], int fctlen){
    for(int it=0;it<fctlen;++it){
        if(fct[it] != COS[it]){
            return 0;
        }
    }
    return 1;
}
int isCOT(char fct[MAX], int fctlen){
    for(int it=0;it<fctlen;++it){
        if(fct[it] != COT[it]){
            return 0;
        }
    }
    return 1;
}
int isTAN(char fct[MAX], int fctlen){
    for(int it=0;it<fctlen;++it){
        if(fct[it] != TAN[it]){
            return 0;
        }
    }
    return 1;
}
int isLN(char fct[MAX], int fctlen){
    for(int it=0;it<fctlen;++it){
        if(fct[it] != LN[it]){
            return 0;
        }
    }
    return 1;
}
int isSQRT(char fct[MAX], int fctlen){
    for(int it=0;it<fctlen;++it){
        if(fct[it] != SQRT[it]){
            return 0;
        }
    }
    return 1;
}
int isABS(char fct[MAX], int fctlen){
    for(int it=0;it<fctlen;++it){
        if(fct[it] != ABS[it]){
            return 0;
        }
    }
    return 1;
}
int isSingleVariabled(char fct[MAX], int fctlen){
    if(isCOS(fct, fctlen) || isTAN(fct, fctlen) || isCOT(fct, fctlen) || isSIN(fct, fctlen) || isLN(fct, fctlen) || isSQRT(fct, fctlen) || isABS(fct, fctlen)){
        return 1;
    }
    return 0;
}

/** Solves for operators: * ^ - + / */
float solveFor2V0(char op, float param1, float param2){
    switch(op){
        case '+':
            return param1 + param2;
            break;
        case '-':
            return param1 - param2;
            break;
        case '*':
            return param1 * param2;
            break;
        case '/':
            return param1 / param2;
            break;
        case '^':
            return (float)pow((float)param1, (float)param2);
            break;
    }
    return 0;
}

/** Solves for operators:  Single parametrized functions*/
Result solveFor1VF(char fct[MAX], int fctlen, float param) {
    if(!isSingleVariabled(fct, fctlen)){
//        //printf("\nResult might vary, because the input is incomplete:\n    err: Only one argument passed to two-argument function!");
        return Result(0.0, true);
    }
    
    if(isSIN(fct, fctlen)){
        return Result((float)sin((float)param), false);
    }
    
    if(isCOS(fct, fctlen)){
        return Result((float)cos((float)param), false);
    }
    
    if(isTAN(fct, fctlen)){
        return Result((float)tan((float)param), false);
    }
    
    if(isCOT(fct, fctlen)){
        return Result(1.0/(float)tan((float)param), false);
    }
    
    if(isLN(fct, fctlen)){
        return Result((float)log((float)param), false);
    }
    if(isSQRT(fct, fctlen)){
        if(param < 0){
//            //printf("Error NaN Sqrt");
            return Result(2, true);
        }
        return Result((float)sqrt((float)param), false);
    }
    
    if(isABS(fct, fctlen)){
        return Result(param > 0 ? param : (-param), false);
    }
//    //printf("\nResult might vary, because a function was not recognised:\n    err: undef");
    return Result(0.0, true);
}





/**Parser Function that writes in the @parsed array, then it converts it to RPN's @outputQueue, and then generates the result.*/

Result parseCreateRPNOQandSolve(char expr[], int len, int trace, float xis){
    
    
    // HAS ERROR
    bool hasError = false;
    
    /** Initially [will] parsed */
    char parsed[MAX][MA20];
    int lengths[MAX];
    int type[MAX];
    float numberValue[MAX];
    
    
    /**
     Output queue
     @pop - pops front
     @push - pushes back
     @all are hard-coded
     */
    float outputQueue[MAX];
    int outputQueueIterator = 0;
    int outQ_End = 0, outQ_Begin = 0;
    char outputQueueChar[MAX][MA20];
    int outputQueueCharLenghts[MAX];
    int outputQueueCharTypes[MAX];
    
    
    
    /**
     Operator Stack
     @pop - pops back
     @push - pushes back
     @all are hard-coded
     */
    char operatorStack[MAX][MA20];
    int opStackLengths[MAX];
    int opertaorStackIterator = 0;
    int opS_End = 0, opS_Begin =0;
    
    /**Parse expr string*/
    int index = 0, i=0;
    while(i<len){
        
        
        if(isDigit(expr[i])){ /**If digit, store the float value in @numberValue and assign type @num @0. This will later be stored in @outputQueue. Also store the value in the @parsed char array*/
            float num = 0.0;
            int p = 0;
            while(isDigit(expr[i])){
                num*=10;
                num+=expr[i] - '0';
                
                parsed[index][p] = expr[i];
                p++;
                i++;
            }
            
            if(expr[i] == '.'){
                parsed[index][p] = expr[i];
                p++;
                i++;
                float po=1.0;
                while(isDigit(expr[i])){
                    po*=10.0;
                    num+=(expr[i] - '0')/po;
                    
                    parsed[index][p] = expr[i];
                    p++;
                    i++;
                }
            }
            lengths[index]  = p;
            type[index] = 0;
            numberValue[index] = num;
            index++;
        } else if(isOperator(expr[i]) || isParanthesis(expr[i])){ /**If is operator or parenthesis assign type accordingly: @1 @op, @4 @par. And store the value in the @parsed char array*/
            parsed[index][0] = expr[i];
            lengths[index]  = 1;
            if(isParanthesis(expr[i])){
                type[index] = 4;
                
            } else {
                type[index] = 1;
                
            }
            
            index++;
            i++;
        } else if('a' <= expr[i] && 'z'>= expr[i]){ /**If it contain letters, it is a function, assign type @3 @fun. And store the value in the @parsed char array*/
            int q = 0;
            while('a' <= expr[i] && 'z'>= expr[i]){
                
                parsed[index][q] = expr[i];
                i++;
                q++;
            }
            lengths[index]  = q;
            type[index] = 3;
            
            index++;
        } else { /**If there is sth else there, probably whitespace, ignore it.*/
            i++;
        }
        
        
        
        
        
    }
    
    /**From @parsed to @outputQueue and @outputQueueChar wiTh RPN*/
    
    /**Define precedence array*/
    int precedence[MAX];
    
    precedence[(int)'*'] = 2;
    precedence[(int)'/'] = 2;
    precedence[(int)'+'] = 1;
    precedence[(int)'-'] = 1;
    precedence[(int)'^'] = 3;
    
    if(trace) {
//        //printf("Size: %d, complexity O(size^2) \n\n", len);
        
    }
    
    int tokensNumber = index;

    
    /** if it's x --> @num @0*/
    for(int it=0;it<tokensNumber;++it){
        if(parsed[it][0] == 'x' && lengths[it]==1){
            type[it] = 0;
        }
    }
    
    
    for(int i=0;i<tokensNumber;++i){
        
        if(type[i] == 0){
            /**Token @i Is Number, so add it to @outputQueue */
            outputQueue[outputQueueIterator] = numberValue[i];
            for(int j=0;j<lengths[i];++j){
                outputQueueChar[outputQueueIterator][j] = parsed[i][j];
            }
            outputQueueCharLenghts[outputQueueIterator] = lengths[i];
            outputQueueIterator++;
            outQ_End++;
        } else if(type[i] == 3){
            /**Token @i Is a function, so add it to @operatorStack */
            for(int j=0;j<lengths[i];++j){
                operatorStack[opertaorStackIterator][j] = parsed[i][j];
            }
            opStackLengths[opertaorStackIterator] = lengths[i];
            opS_End++;
            opertaorStackIterator++;
            
        } else if(type[i] == 1){
            
            /**Token is an operator*/
            char o1 = parsed[i][0];
            while(operatorStack[opS_End - 1][0] != '(' && isOperator(operatorStack[opS_End - 1][0]) && ( precedence[(int)o1] < precedence[(int)operatorStack[opS_End - 1][0]] ||
                                                                                                        (precedence[(int)o1] == precedence[(int)operatorStack[opS_End - 1][0]]) )){
                /**there is an operator o2 other than the left parenthesis at the top
                 of the operator stack, and (o2 has greater precedence than o1
                 or they have the same precedence and o1 is  [NOT IMPLEMENTED YET] left-associative)*/
                char o2 = operatorStack[opS_End - 1][0];
                
                /**Pop o2*/
                opS_End --;
                opertaorStackIterator --;
                
                /**Add o2 to @outputQueue */
                outputQueueChar[outputQueueIterator][0] = o2;
                outputQueueCharLenghts[outputQueueIterator] = 1;
                outputQueueIterator ++;
                outQ_End++;
                
            }
            /**Push o1 to @operatorStack */
            operatorStack[opertaorStackIterator][0] = o1;
            opStackLengths[opertaorStackIterator] = 1;
            opertaorStackIterator ++;
            opS_End++;
            
        } else if(type[i] == 4 && parsed[i][0] == '('){
            /**Push ( to @opertaorStack */
            operatorStack[opertaorStackIterator][0] = parsed[i][0];
            opStackLengths[opertaorStackIterator] = 1;
            opertaorStackIterator ++;
            opS_End ++;
        } else if(type[i] == 4 && parsed[i][0] == ')'){
            while(operatorStack[opS_End - 1][0] != '('){
                if(opS_End <= opS_Begin){
                    /**Expression is incomplete*/
//                    //printf("\nExpression is incomplete! \n at: %d", i);
                    hasError = true;
                    return Result(2, true);
                }
                
                char o2 = operatorStack[opS_End - 1][0];
                
                /**Pop o2*/
                opS_End --;
                opertaorStackIterator --;
                
                /**Add o2 to charQueue*/
                outputQueueChar[outputQueueIterator][0] = o2;
                outputQueueCharLenghts[outputQueueIterator] = 1;
                outputQueueIterator ++;
                outQ_End++;
                
            }
            
            /** There must be  a left parenthesis at the top of @operatorStack */
            
            /** If not, return error!*/
            if(operatorStack[opS_End - 1][0] != '('){
//                //printf("Something went wrong \n at: %d", i);
                hasError = true;
                return Result(2, true);
            }
            
            /**else, all is good, discard it and go on*/
            opS_End --;
            opertaorStackIterator --;
            
            /**If we have a function token at the top [basically if the first letter is not an operator or parenthesis]*/
            
            if(!(isOperator(operatorStack[opS_End - 1][0])) && !(isParanthesis(operatorStack[opS_End - 1][0]))){
                /**Pop the function from the @operatorStack into the outputQueue*/
                
                /**Add to @outputQueue */
                for(int j=0; j<opStackLengths[opS_End - 1]; ++j){
                    outputQueueChar[outputQueueIterator][j] = operatorStack[opS_End - 1][j];
                }
                outputQueueCharLenghts[outputQueueIterator] = opStackLengths[opS_End - 1];
                outputQueueIterator ++;
                outQ_End++;
                
                /**Pop from @opStack*/
                opS_End --;
                opertaorStackIterator --;
            }
            
            
            
        }
        
        
        
        
    }
    /** Transfer the rest of the @operatorStack into the @outputQueue */
    while(opS_Begin < opS_End){
        if(operatorStack[opS_End - 1][0] == '('){
//            //printf("\nExpression is incomplete! \n    err: unclosed '('.");
            hasError = true;
            return Result(0, true);
        }
        
        /**Pop the function from the @operatorStack into the outputQueue*/
        
        /**Add to @outputQueue */
        for(int j=0; j<opStackLengths[opS_End - 1]; ++j){
            outputQueueChar[outputQueueIterator][j] = operatorStack[opS_End - 1][j];
        }
        outputQueueCharLenghts[outputQueueIterator] = opStackLengths[opS_End - 1];
        outputQueueIterator ++;
        outQ_End++;
        
        /**Pop from @opStack*/
        opS_End --;
        opertaorStackIterator --;
        
        
    }
    
    /** The RPN array is: @outputQueueChar , with it's dual (the one containing the float correspondents on the corresponding positions -- same as in @outputQueueChar) being @outputQueue */
    
    /** Rough type assignment (remember that we got rid of the parentheses!) */
    /**
     0 - NUMBER
     1 - OPERATOR
     3 - FUNCTION
     4 - PARANTHESIS
     */
    for(int it = outQ_Begin; it<outQ_End;++it){
        if(outputQueueCharLenghts[it] == 1 && isOperator(outputQueueChar[it][0])){
            /** It's an operator */
            outputQueueCharTypes[it] = 1;
            
        } else {
            int sw = 0;
            for(int j=0;j<outputQueueCharLenghts[it];++j){
                if(isLetter(outputQueueChar[it][j])){
                    /** It is clearly a function*/
                    outputQueueCharTypes[it] = 3;
                    sw=1;
                    break;
                }
            }
            if(sw == 0) {
                outputQueueCharTypes[it] = 0;
                
            }
        }
        
        
        
    }
    
    
    /** Some checking :)*/
    
    
    
    /**Done checking*/
    
    
    /**Solve RPN*/
    
    
    /**Replace variable with @xis*/
    for(int it = outQ_Begin; it<outQ_End;++it){
        /**IF Variable is found*/
        if(outputQueueChar[it][0] == 'x' && outputQueueCharLenghts[it]==1){
            /**Treat it as number and replace it with @xis*/
            outputQueueCharTypes[it] = 0;
            outputQueue[it]= xis;
            
        }
    }
    
    /**
     0 - NUMBER
     1 - OPERATOR
     NEW: 2 - FUNCTION (2 VARS - ACTS LIKE OPERATOR)
     3 - FUNCTION (SINGLE - VARRED)
     4 - PARANTHESIS
     9 - DELETED
     */
    
    for(int it = outQ_Begin; it<outQ_End;++it){
        /**If it is a function*/
        
        if(outputQueueCharTypes[it] == 3){
            int isSinglVar = isSingleVariabled(outputQueueChar[it], outputQueueCharLenghts[it]);
            
            /** If it isn't singleVarred, change the type to @2 */
            if(!isSinglVar){
                outputQueueCharTypes[it] = 2;
            }
            
        }
        
    }
    
    /** FROM NOW ON, THE NUMBERS WILL BE TAKEN ONLY FROM @outputQueue */
    
    int deleted = 0;
    /** @outputQueueChar , @outputQueueCharTypes , @outputQueueCharLengths */
    
    outputQueueIterator = outQ_Begin;
    
    int outQ_Len = outQ_End - outQ_Begin;
    
    /** Array that memorises the next positions, initially, next[i]=i+1*/
    
    int next[MAX + 1], prev[MAX +1];
    for(int it = outQ_Begin; it< outQ_End; ++it){
        next[it] = it+1;
        prev[it] = it-1;
    }
    next[outQ_End] = 0;
    prev[outQ_End] = outQ_End - 1;
    
    while(outQ_Len - deleted > 1){
        for(int it = next[outQ_End]; it< outQ_End; it = next[it]){
            /** If it is operator*/
            if(outputQueueCharTypes[it] == 1){
                /** If both the previous tokes are numbers */
                /**
                 We have a config like @num @num @op. So we solve it!
                 */
                if(outputQueueCharTypes[prev[prev[it]]] == 0 && outputQueueCharTypes[prev[it]] == 0 && it>=2){
                    /**Get the 2 nrs before*/
                    float param1 = outputQueue[prev[prev[it]]];
                    float param2 = outputQueue[ prev[it] ];
                    
                    
                    float result = solveFor2V0(outputQueueChar[it][0], param1, param2);
                    
                    /** Replace operator val at @it wit the result for @outputQueue, and also change the type to number so we know to read said val from @outputQueue, and not from @outputQueueChar*/
                    /** The separation between floats and chars is made to be able to save time in not performing an eventual float to string or string to float operation*/
                    
                    outputQueueCharTypes[it] = 0;
                    outputQueue[it] = result;
                    
                    /**Delete positions prev[it] and prev[prev[it]] */
                    
                    outputQueueCharTypes[prev[it]] = 9;
                    outputQueueCharTypes[ prev[prev[it]] ] = 9;
                    if(it<2){
//                        //printf("\nRPN solving failed at %d, \n   err: 2 Valued operator found with one argument!", it);
                        hasError = true;
                        return Result(0, true);
                    }
                    next[prev[prev[prev[it]]]] = it;
                    prev[it] = prev[prev[prev[it]]];
                    deleted += 2;
                }
            } else if(outputQueueCharTypes[it] == 3 && it>=1){ /**If the current token is a single param function*/
                /** If the token before is a number, apply the function!*/
                if( outputQueueCharTypes[prev[it]] == 0){
                    /**Get the nr before*/
                    float param = outputQueue[ prev[it] ];
                    
                    Result resultR = solveFor1VF(outputQueueChar[it], outputQueueCharLenghts[it], param);
                    if(resultR.hasError) {
                        return Result(0, true);
                    }
                    float result = resultR.number;
                    
                    /** Replace operator val at @it wit the result for @outputQueue, and also change the type to number so we know to read said val from @outputQueue, and not from @outputQueueChar*/
                    /** The separation between floats and chars is made to be able to save time in not performing an eventual float to string or string to float operation*/
                    
                    outputQueueCharTypes[it] = 0;
                    outputQueue[it] = result;
                    
                    /**Delete position prev[it] */
                    
                    outputQueueCharTypes[prev[it]] = 9;
                    if(it<1){
//                        //printf("\nRPN solving failed at %d, \n   err: 2 Valued operator found with one argument!", it);
                        hasError = true;
                        return Result(0, true);
                        
                    }
                    next[prev[prev[it]]] = it;
                    prev[it] = prev[prev[it]];
                    deleted += 1;
                }
                
                
                
            }
        }
        
    }
   
    
    float rr = outputQueue[outQ_End - 1];
    return Result(rr, hasError);
    
    
    
}




float semiFunc(float x) {
    return metal::log(x);
}

float FUNC(float x) {
    float ry = semiFunc(x / 100) * 100;
    return ry;
    
}


float round2D(float var) {
    return var;
}


bool isinfe(float x, float s) {
    return metal::abs(x) > 200;
}

#define DX 1
#define THRESH 1000

float roundoff(float value) {
    float pow_10 = 100;
    return round(value * pow_10) / pow_10;
}

kernel void compute_graph (metal::texture2d<float, metal::access::read_write> output [[ texture(0) ]],
                     constant metal::float2x2 &os [[ buffer(0) ]],
                     constant char * eq [[ buffer(1) ]],
                     constant int &eqlen [[ buffer(2) ]],
                     ushort2 gid [[ thread_position_in_grid ]]) {
//    output.write(float4(1,0,0,1), gid);
    int w = output.get_width();
    int h = output.get_height();
//    int nnx = (gid.x - w / 2) ;
    int nnxm1 = (gid.x - DX - w / 2) ;
    int nnxp1 = (gid.x + DX - w / 2) ;
    
    
    
    float s = os[1][1];
    
    
    int nxm1 = (nnxm1 - os[0][0]);
    int nxp1 = (nnxp1 - os[0][0]);
    
    
    
    int D = 100;
    int gx = gid.x;
    
    if (gid.y == 0) {
        char e[100];
        for(int i=0;i<eqlen;i++) {
            e[i] = (char)eq[i];
        }
        Result yfuncm1 = parseCreateRPNOQandSolve(e, 100, 0, (float)nxm1 /( 100.0 * s));
        Result yfuncp1 = parseCreateRPNOQandSolve(e, 100, 0, (float)nxp1 /( 100.0 * s));
        
        
        
        if(!yfuncm1.hasError && !yfuncp1.hasError) {
            int gidym1 = round((int)(-roundoff(yfuncm1.number * s * 100) ) + os[0][1] + h/2);
            int gidyp1 = round((int)(-roundoff(yfuncp1.number * s * 100) ) + os[0][1] + h/2);
                for(int i = 0; i <= h; i++) {
                    
                        if((gidyp1 <= i && i <= gidym1) || (gidym1 <= i && i <= gidyp1)) {
                            if(abs(gidyp1 - gidym1) <= THRESH) {
                                output.write(float4(0,0.478,1,1), metal::uint2(gx, (int)i));
                            } else {
                                output.write(float4(0,0,0,1), metal::uint2(gx, (int)i));
                            }
                        } else {
                            if(-2 / s <= fmod((i - h/2 - os[0][1]) / s, D) && fmod((i - h/2 - os[0][1]) / s, D) <= 2 / s) {
                                if(os[1][0] == 1) {
                                    output.write(float4(0.19,0.19,0.21,1), metal::uint2(gx, (int)i));
                                } else {
                                    output.write(float4(0.7,0.7,0.75,1), metal::uint2(gx, (int)i));
                                }
                            } else {
                                
                                if(os[1][0] == 1) {
                                    output.write(float4(0.1,0.1,0.12,1), metal::uint2(gx, (int)i));
                                } else {
                                    output.write(float4(1,1,1,1), metal::uint2(gx, (int)i));
                                }
                            }
                        }
                    
                }
            
            int ii = gx;
            for(int j=0; j<=h;j++) {
                
                if((gidyp1 <= j && j <= gidym1) || (gidym1 <= j && j <= gidyp1)) {
                    if(abs(gidyp1 - gidym1) <= THRESH ) {
                        output.write(float4(0,0.478,1,1), metal::uint2(gx, (int)j));
                    } else {
                        output.write(float4(0,0,0,1), metal::uint2((int)ii, j));;
                    }
                } else if(-2 / s <= fmod((ii - w/2 - os[0][0]) / s, D) && fmod((ii - w/2 - os[0][0]) / s, D) <= 2 / s) {
                    if (os[1][0] == 1) {
                        output.write(float4(0.19,0.19,0.21,1), metal::uint2((int)ii, j));
                    } else {
                        output.write(float4(0.7,0.7,0.75,1), metal::uint2((int)ii, j));
                        
                    }
                }
                
            }
        } else {
            for(int i = 0; i <= h; i++) {
                if(-2 / s <= fmod((i - h/2 - os[0][1]) / s, D) && fmod((i - h/2 - os[0][1]) / s, D) <= 2 / s) {
                    if(os[1][0] == 1) {
                        output.write(float4(0.19,0.19,0.21,1), metal::uint2(gx, (int)i));
                    } else {
                        output.write(float4(0.7,0.7,0.75,1), metal::uint2(gx, (int)i));
                    }
                } else {
                    if(os[1][0] == 1) {
                        output.write(float4(0.1,0.1,0.12,1), metal::uint2(gx, (int)i));
                    } else {
                        output.write(float4(1,1,1,1), metal::uint2(gx, (int)i));
                    }
                }
            }
            int ii = gx;
            for(int j=0; j<=h;j++) {
                    if(-2 / s <= fmod((ii - w/2 - os[0][0]) / s, D) && fmod((ii - w/2 - os[0][0]) / s, D) <= 2 / s) {
                        if (os[1][0] == 1) {
                            output.write(float4(0.19,0.19,0.21,1), metal::uint2((int)ii, j));
                        } else {
                            output.write(float4(0.7,0.7,0.75,1), metal::uint2((int)ii, j));
                            
                        }
                    }
                
            }
        }
    }
    
}
