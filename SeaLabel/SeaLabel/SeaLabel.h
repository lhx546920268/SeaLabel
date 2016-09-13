//
//  SeaLabel.h
//  SeaLabel
//
//  Created by 罗海雄 on 16/9/5.
//  Copyright © 2016年 qianseit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SeaLabel;

/**自定义Label，可识别链接，点击时可打开该链接
 *使用coreText实现，在设置富文本的时候要使用 coreText的属性，否则会出现无法预料的后果
 *如 设置字体颜色要用 kCTForegroundColorAttributeName，而不是 NSForegroundColorAttributeName
 */
@interface SeaLabel : UIView<UIGestureRecognizerDelegate>

/**要显示的文本
 */
@property(nonatomic,copy) NSString *text;

/**文本颜色
 */
@property(nonatomic,strong) UIColor *textColor;

/**字体
 */
@property(nonatomic,strong) UIFont *font;

/**内容对齐方式 default is 'NSTextAlignmentLeft'
 */
@property(nonatomic,assign) NSTextAlignment textAlignment;

/**是否识别链接，default is 'YES'
 */
@property(nonatomic,assign) BOOL identifyURL;

/**URL和其他设置可点击的 样式 默认蓝色字体加下划线
 */
@property(nonatomic,strong) NSDictionary *selectableAttributes;

/**点击的高亮的背景颜色 default is '[UIColor colorWithWhite:0.3 alpha:0.5]'
 */
@property(nonatomic,strong) UIColor *highlightedBackgroundColor;

/**高亮圆角 default is '3.0'
 */
@property(nonatomic,assign) CGFloat highlightedBackgroundCornerRadius;

/**文字与边框的距离 default is 'UIEdgeInsetsZero'
 */
@property(nonatomic,assign) UIEdgeInsets textInsets;

/**文字与文字间的距离 default 1.0
 */
@property(nonatomic,assign) CGFloat wordSpace;

/**行距 default is '0'
 */
@property(nonatomic,assign) CGFloat lineSpace;

/**点击识别的字符串回调
 */
@property(nonatomic,copy) void(^selectStringHandler)(NSString *string);

/**获取默认的富文本
 *@param string 要生成富文本的字符串
 *@return 根据 font textColor textAlignment 生成的富文本
 */
- (NSMutableAttributedString*)defaultAttributedTextFromString:(NSString*) string;

/**添加可点击的位置，重新设置text会忽略以前添加的
 *@param range 可点击的位置，如果该范围不在text中，则忽略
 */
- (void)addSelectableRange:(NSRange) range;

@end

