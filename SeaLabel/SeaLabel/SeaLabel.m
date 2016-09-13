//
//  SeaLabel.m
//  SeaLabel
//
//  Created by 罗海雄 on 16/9/5.
//  Copyright © 2016年 qianseit. All rights reserved.
//

#import "SeaLabel.h"
#import <CoreText/CoreText.h>

//系统默认的蓝色
#define _UIKitTintColor_ [UIColor colorWithRed:0 green:0.4784314 blue:1.0 alpha:1.0]

/**链接识别 正则表达式
 */
static NSString *const SeaURLRegex = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";

@interface SeaLabel ()
{
    /**文本帧合成器
     */
    CTFramesetterRef _framesetter;
    
    /**文本帧
     */
    CTFrameRef _ctFrame;
    
    /**富文本
     */
    NSMutableAttributedString *_attributedText;
}

/**文本帧合成器
 */
@property(nonatomic,readonly) CTFramesetterRef framesetter;

/**文本帧
 */
@property(nonatomic,readonly) CTFrameRef ctFrame;

/**可点击的位置，数组元素是 NSValue rangeValue
 */
@property(nonatomic,strong) NSMutableArray *selectableRanges;

/**URL正则表达式执行器
 */
@property(nonatomic,strong) NSRegularExpression *expression;

/**长按手势
 */
@property(nonatomic,strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

/**文本框
 */
@property(nonatomic,assign) CGRect textBounds;

/**高亮的位置
 */
@property(nonatomic,assign) NSRange highlightedRange;

@end

@implementation SeaLabel

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self initialization];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self initialization];
    }
    
    return self;
}

///初始化
- (void)initialization
{
    self.backgroundColor = [UIColor clearColor];
    self.textColor = nil;
    self.font = nil;
    self.highlightedBackgroundColor = nil;
    self.highlightedBackgroundCornerRadius = 3.0;
    
    self.identifyURL = YES;
    _textAlignment = NSTextAlignmentLeft;
    _wordSpace = 1.0;
    self.expression = [NSRegularExpression regularExpressionWithPattern:SeaURLRegex options:NSRegularExpressionCaseInsensitive error:nil];
    
    self.selectableAttributes = nil;
    self.highlightedBackgroundColor = nil;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.delegate = self;
    longPress.minimumPressDuration = 0.01;
    [self addGestureRecognizer:longPress];
    self.longPressGestureRecognizer = longPress;
}

#pragma mark- dealloc

- (void)dealloc
{
    if(_framesetter != NULL)
    {
        CFRelease(_framesetter);
    }
    
    if(_ctFrame != NULL)
    {
        CFRelease(_ctFrame);
    }
}

#pragma mark- text

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if(_attributedText)
    {
        [self redrawText];
    }
}

- (CTFramesetterRef)framesetter
{
    if(_framesetter == NULL)
    {
        @synchronized(self){
            
            _framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) self.attributedText);
        }
    }
    
    return _framesetter;
}

- (CTFrameRef)ctFrame
{
    return _ctFrame;
}

- (CTFrameRef)ctFrameFromRect:(CGRect) rect
{
    if(_ctFrame == NULL)
    {
        @synchronized (self){
            
            //开始绘制
            CGMutablePathRef path = CGPathCreateMutable();
            CGRect bounds = CGRectMake(_textInsets.left, _textInsets.top, rect.size.width - _textInsets.left - _textInsets.right, rect.size.height - _textInsets.top - _textInsets.bottom);
            CGPathAddRect(path, NULL, bounds);
            self.textBounds = bounds;
            
            NSLog(@"%@", NSStringFromCGRect(bounds));
            
            //文本框大小
            _ctFrame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, 0), path, NULL);
            
            CFRelease(path);
        }
    }
    
    return _ctFrame;
}

- (void)setText:(NSString *)text
{
    if(![self.text isEqualToString:text])
    {
        self.attributedText = [self defaultAttributedTextFromString:text];
    }
}

- (NSString*)text
{
    return self.attributedText.string;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    if(_attributedText != attributedText)
    {
        _attributedText = [attributedText mutableCopy];
        [self redrawText];
    }
}

- (NSAttributedString*)attributedText
{
    return _attributedText;
}

#pragma mark- property

- (void)setTextColor:(UIColor *)textColor
{
    if(!textColor)
    {
        textColor = [UIColor blackColor];
    }
    if(_textColor != textColor)
    {
        _textColor = textColor;
        
        if(_attributedText)
        {
            [_attributedText addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)_textColor.CGColor range:NSMakeRange(0, _attributedText.length)];
            [self setSelectableAttributesWithAttributedText:_attributedText];
            [self redrawText];
        }
    }
}

- (void)setFont:(UIFont *)font
{
    if(!font)
    {
        font = [UIFont systemFontOfSize:17.0];
    }
    if(_font != font)
    {
        _font = font;
        if(_attributedText)
        {
            CTFontRef font = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
            [_attributedText addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)font  range:NSMakeRange(0, _attributedText.length)];
            [self setSelectableAttributesWithAttributedText:_attributedText];
            [self redrawText];
        }
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    if(_textAlignment != textAlignment)
    {
        _textAlignment = textAlignment;
        
        if(_attributedText)
        {
            [self setParagraphStyleWithAttributedText:_attributedText];
            [self redrawText];
        }
    }
}

- (void)setWordSpace:(CGFloat)wordSpace
{
    if(_wordSpace != wordSpace)
    {
        _wordSpace = wordSpace;
        
        if(_attributedText)
        {
            [_attributedText addAttribute:(NSString*)kCTKernAttributeName value:[NSNumber numberWithFloat:self.wordSpace] range:NSMakeRange(0, _attributedText.length)];
            [self redrawText];
        }
    }
}

- (void)setLineSpace:(CGFloat)lineSpace
{
    if(_lineSpace != lineSpace)
    {
        _lineSpace = lineSpace;
        if(_attributedText)
        {
            [self setParagraphStyleWithAttributedText:_attributedText];
            [self redrawText];
        }
    }
}


- (void)setSelectableAttributes:(NSDictionary *)selectableAttributes
{
    if(!selectableAttributes)
    {
        selectableAttributes = [NSDictionary dictionaryWithObjectsAndKeys:(id)[_UIKitTintColor_ CGColor], (NSString*)kCTForegroundColorAttributeName, [NSNumber numberWithBool:YES], (NSString *)kCTUnderlineStyleAttributeName, nil];
    }
    if(_selectableAttributes != selectableAttributes)
    {
        _selectableAttributes = selectableAttributes;
        
        if(_attributedText && self.selectableRanges.count > 0)
        {
            [self setSelectableAttributesWithAttributedText:_attributedText];
            [self redrawText];
        }
    }
}

- (void)setHighlightedBackgroundColor:(UIColor *)highlightedBackgroundColor
{
    if(!highlightedBackgroundColor)
    {
        highlightedBackgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    }
    if(_highlightedBackgroundColor != highlightedBackgroundColor)
    {
        _highlightedBackgroundColor = highlightedBackgroundColor;
    }
}

- (void)setHighlightedRange:(NSRange)highlightedRange
{
    if(!NSEqualRanges(_highlightedRange, highlightedRange))
    {
        _highlightedRange = highlightedRange;
        [self setNeedsDisplay];
    }
}

#pragma mark- public method

/**获取默认的富文本
 *@param string 要生成富文本的字符串
 *@return 根据 font textColor textAlignment 生成的富文本
 */
- (NSMutableAttributedString*)defaultAttributedTextFromString:(NSString*) string
{
    if(!string)
    {
        return [[NSMutableAttributedString alloc] init];
    }
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:string];
    
    CTFontRef font = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    [attributedText addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)font  range:NSMakeRange(0, attributedText.length)];
    [attributedText addAttribute:(NSString*)kCTKernAttributeName value:[NSNumber numberWithFloat:self.wordSpace] range:NSMakeRange(0, attributedText.length)];
    [attributedText addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)self.textColor.CGColor range:NSMakeRange(0, attributedText.length)];
    CFRelease(font);
    
    [self setSelectableAttributesWithAttributedText:attributedText];
    
    [self setParagraphStyleWithAttributedText:attributedText];
    
    return attributedText;
}

/**添加可点击的位置
 *@param range 可点击的位置，如果该范围不在text中，则忽略
 */
- (void)addSelectableRange:(NSRange) range
{
    if(range.location + range.length <= self.text.length)
    {
        [self.selectableRanges addObject:[NSValue valueWithRange:range]];
        [_attributedText addAttributes:self.selectableAttributes range:range];
        [self redrawText];
    }
}

#pragma mark- private method

///设置样式
- (void)setSelectableAttributesWithAttributedText:(NSMutableAttributedString*) attributedText
{
    if(self.identifyURL && attributedText)
    {
        //获取url
        [self URLsFromString:attributedText.string];
        //设置url样式
        for(NSValue *result in self.selectableRanges)
        {
            [attributedText addAttributes:self.selectableAttributes range:result.rangeValue];
        }
    }
}

///设置段落样式
- (void)setParagraphStyleWithAttributedText:(NSMutableAttributedString*) attributedText
{
    if(attributedText)
    {
        //换行模式
        CTParagraphStyleSetting lineBreadMode;
        CTLineBreakMode linkBreak = kCTLineBreakByCharWrapping;
        lineBreadMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
        lineBreadMode.value = &linkBreak;
        lineBreadMode.valueSize = sizeof(CTLineBreakMode);
        
        //行距
        CTParagraphStyleSetting lineSpaceMode;
        CGFloat lineSpace = self.lineSpace;
        lineSpaceMode.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
        lineSpaceMode.value = &lineSpace;
        lineSpaceMode.valueSize = sizeof(CGFloat);
        
        //对齐方式
        CTTextAlignment textAlignment;
        switch (self.textAlignment)
        {
            case NSTextAlignmentLeft:
                textAlignment = kCTTextAlignmentLeft;
                break;
            case NSTextAlignmentCenter :
                textAlignment = kCTTextAlignmentCenter;
                break;
            case NSTextAlignmentJustified :
                textAlignment = kCTTextAlignmentJustified;
                break;
            case NSTextAlignmentNatural :
                textAlignment = kCTTextAlignmentNatural;
                break;
            case NSTextAlignmentRight :
                textAlignment = kCTTextAlignmentRight;
                break;
        }
        
        CTParagraphStyleSetting alignment;
        alignment.spec = kCTParagraphStyleSpecifierAlignment;
        alignment.valueSize = sizeof(textAlignment);
        alignment.value = &textAlignment;
        
        CTParagraphStyleSetting setting[] = {lineBreadMode, alignment, lineSpaceMode};
        
        CTParagraphStyleRef style = CTParagraphStyleCreate(setting, 3);
        [attributedText addAttribute:(NSString*)kCTParagraphStyleAttributeName value:(__bridge id)style range:NSMakeRange(0, attributedText.length)];
        CFRelease(style);
    }
}

#pragma mark- draw

///重绘文字
- (void)redrawText
{
    if(_framesetter != NULL)
    {
        CFRelease(_framesetter);
    }
    
    if(_ctFrame != NULL)
    {
        CFRelease(_ctFrame);
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if(_attributedText)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);//设置字形变换矩阵为CGAffineTransformIdentity，也就是说每一个字形都不做图形变换
        
        //翻转，coreText的坐标系和UIKit的坐标系的 y轴相反的 ，coreText的坐标原点在坐下角
        CGAffineTransform transform = CGAffineTransformMake(1, 0, 0, -1, 0, rect.size.height);///相对于x轴翻转180度
        CGContextConcatCTM(context, transform);
        
        CTFrameRef frame = [self ctFrameFromRect:rect];
        CTFrameDraw(frame, context);
        
        if(_highlightedRange.location != NSNotFound && _highlightedRange.length > 0)
        {
            CGMutablePathRef path = CGPathCreateMutable();
            CGContextSetFillColorWithColor(context, _highlightedBackgroundColor.CGColor);
            NSArray *rects = [self rectsForRange:_highlightedRange];
            for(NSString *rectStr in rects)
            {
                CGPathAddRoundedRect(path, NULL, CGRectFromString(rectStr), _highlightedBackgroundCornerRadius, _highlightedBackgroundCornerRadius);
            }
            
            CGContextAddPath(context, path);
            CGContextFillPath(context);
            CGPathRelease(path);
        }
    }
}

/**获取某个文本范围的矩形框
 *@param range 文本范围
 *@return 矩形框
 */
- (NSArray*)rectsForRange:(NSRange) range;
{
    if(self.ctFrame == NULL)
        return nil;
    NSMutableArray *rects = [NSMutableArray array];
    
    CFArrayRef lines = CFRetain(CTFrameGetLines(self.ctFrame));
    
    NSInteger count = CFArrayGetCount(lines);
    CGPoint lineOrigins[count];
    CTFrameGetLineOrigins(self.ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    for(NSInteger i = 0;i < count;i ++)
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);
        
        NSRange innerRange = [self innerRangeBetweenOne:range andSecond:NSMakeRange(lineRange.location == kCFNotFound ? NSNotFound : lineRange.location, lineRange.length)];
        
        
        if(innerRange.location != NSNotFound && innerRange.length > 0)
        {
            CGFloat lineAscent;
            CGFloat lineDescent;
            CGFloat lineLeading;
            
            //获取文字排版
            CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
            CGFloat startX = CTLineGetOffsetForStringIndex(line, innerRange.location, NULL);
            CGFloat endX = CTLineGetOffsetForStringIndex(line, innerRange.location + innerRange.length, NULL);
            
            ///行末尾，但是末尾部分无法显示一个字，要占满
            if(i != count - 1 && innerRange.location + innerRange.length == lineRange.length + lineRange.location)
            {
                endX = CGRectGetMaxX(self.textBounds);
            }
            
            CGPoint lineOrigin = lineOrigins[i];
            
            CGRect rect = CGRectMake(lineOrigin.x + startX + self.textInsets.left, lineOrigin.y - lineDescent + self.textInsets.top, endX - startX, lineAscent + lineDescent + lineLeading);
            
            [rects addObject:NSStringFromCGRect(rect)];
        }
        else if(lineRange.location > range.location + range.length)
            break;
    }
    
    
    return rects;
}

/**获取内部的range
 */
- (NSRange)innerRangeBetweenOne:(NSRange) one andSecond:(NSRange) second
{
    NSRange range = NSMakeRange(NSNotFound, 0);
    
    //交换
    if(one.location > second.location)
    {
        NSRange tmp = one;
        one = second;
        second = tmp;
    }
    
    if(second.location < one.location + one.length)
    {
        range.location = second.location;
        
        NSInteger end = MIN(one.location + one.length, second.location + second.length);
        range.length = end - range.location;
    }
    
    return range;
}

#pragma mark- range

/**识别文本中的URL
 */
- (void)URLsFromString:(NSString*) str
{
    if(str == nil || [str isEqual:[NSNull null]])
    {
        self.selectableRanges = nil;
        return;
    }
    
    NSArray *results = [self.expression matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:results.count];
    
    for(NSTextCheckingResult *result in results)
    {
        [ranges addObject:[NSValue valueWithRange:result.range]];
    }
    
    self.selectableRanges = ranges;
}

//获取点中的字符串
- (NSRange)selectableStringAtPoint:(CGPoint) point
{
    NSRange range = NSMakeRange(NSNotFound, 0);
    //判断点击处是否在文本内
    CGRect textRect = self.textBounds;
    if (!CGRectContainsPoint(textRect, point))
    {
        return range;
    }
    
    //转换成coreText 坐标
    point = CGPointMake(point.x, textRect.size.height - point.y);
    
    ///行数为0
    CFArrayRef lines = CTFrameGetLines(_ctFrame);
    NSUInteger numberOfLines = CFArrayGetCount(lines);
    if (numberOfLines == 0)
    {
        return range;
    }
    
    ///行起点
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    ///获取点击的行的位置，数组是倒序的
    NSUInteger lineIndex;
    for(lineIndex = 0;lineIndex < numberOfLines;lineIndex ++)
    {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CGFloat lineDescent;
        CTLineGetTypographicBounds(line, NULL, &lineDescent, NULL);
        
        if (lineOrigin.y - lineDescent - self.textInsets.top < point.y)
        {
            break;
        }
    }

    if(lineIndex >= numberOfLines)
    {
        return range;
    }
    
    ///获取行信息
    CGPoint lineOrigin = lineOrigins[lineIndex];
    
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    
    //把坐标转成行对应的坐标
    CGPoint position = CGPointMake(point.x - lineOrigin.x - self.textInsets.left, point.y - lineOrigin.y);
    
    ///获取该点的字符位置，从整个字符串的倒序开始
    CFIndex index = CTLineGetStringIndexForPosition(line, position);
    
    //检测字符位置是否超出该行字符的范围，有时候行的末尾不够现实一个字符了，点击该空旷位置时无效
    CFIndex glyphCount = CTLineGetGlyphCount(line); ///该行所有字形的数量
    CFRange stringRange = CTLineGetStringRange(line); ///该行相对于整个字符串的范围，从整个字符串的倒序开始
    
    if((index - stringRange.location) == glyphCount)
    {
        return range;
    }
    
    ///获取对应的可点信息
    for(NSValue *result in self.selectableRanges)
    {
        NSRange rangeValue = result.rangeValue;
        if(rangeValue.location <= index && index <= (rangeValue.location + rangeValue.length - 1))
        {
            range = rangeValue;
            break;
        }
    }
    
    return range;
}

#pragma mark- gesture

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return [self selectableStringAtPoint:[touch locationInView:self]].location != NSNotFound;
}

///点击事件
- (void)handleLongPress:(UILongPressGestureRecognizer*) longPress
{
    CGPoint point = [longPress locationInView:self];
    
    switch (longPress.state)
    {
        case UIGestureRecognizerStateBegan :
        {
            self.highlightedRange = [self selectableStringAtPoint:point];
        }
            break;
        case UIGestureRecognizerStateChanged :
        {
            self.highlightedRange = [self selectableStringAtPoint:point];
        }
            break;
        case UIGestureRecognizerStateEnded :
        {
            NSRange range = [self selectableStringAtPoint:[longPress locationInView:self]];
            self.highlightedRange = NSMakeRange(NSNotFound, 0);
            
            if(range.location == NSNotFound)
                return;

            if(self.selectStringHandler)
            {
                self.selectStringHandler([self.text substringWithRange:range]);
            }
        }
            break;
        default:
        {
            self.highlightedRange = NSMakeRange(NSNotFound, 0);
        }
            break;
    }
    
}

@end
