//
//  TYPEID_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Label_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doTextHelper.h"
#import "doDefines.h"

#define FONT_OBLIQUITY 15.0

@implementation do_Label_UIView
{
    NSString *_myFontStyle;
    NSString *_myFontFlag;
    NSString *_myTextAlign;
    NSString *_fontColor;
    NSString *_myShadow;
    
    float maxWidth;
    float maxHeight;
    int _intFontSize;
    
    NSInteger _linesSpace;
    
    NSMutableParagraphStyle *_paragraphStyle;
    
    NSString *newText;
}

#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;

    _paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];

    maxWidth = MAXFLOAT;
    maxHeight = MAXFLOAT;
    [self change_maxLines:[_model GetProperty:@"maxLines"].DefaultValue];
    [self change_fontColor:[_model GetProperty:@"fontColor"].DefaultValue];
    _intFontSize = [[_model GetProperty:@"fontSize"].DefaultValue intValue];
    [self change_fontSize:[@(_intFontSize) stringValue]];
    [self change_linesSpace:[_model GetProperty:@"linesSpace"].DefaultValue];
    newText = @"";
    [self change_shadow:[_model GetProperty:@"shadow"].DefaultValue];

}
//销毁所有的全局对象
- (void) OnDispose
{
    _model = nil;
    _myFontStyle = nil;
    _myFontFlag = nil;
    //自定义的全局属性
}
//实现布局
- (void) OnRedraw
{
    //重新调整视图的x,y,w,h
    BOOL isAutoHeight = [self isAutoHeight];
    BOOL isAutoWidth = [self isAutoWidth];
    
    if(isAutoHeight||isAutoWidth)
    {
        float cWidth,cHeight;
        if(isAutoWidth){
            cWidth =  maxWidth;
        }else{
            cWidth = _model.RealWidth;
        }
        if(isAutoHeight){
            cHeight = maxHeight;
        }else{
            cHeight = _model.RealHeight;
        }
        CGSize size = [self autoSize:cWidth :cHeight ];
        //将float改为int，iOS坑：有的时候label右侧会出现黑色边框：计算每个label的frame时因为是根据text的文字多少与字体大小有关，造成frame的size中width、height有小数部分。
        int lastwidth = size.width;
        int lastheight = size.height;
        
        //以下两种保留小数点后两位的方法都是不准确的，得到的frame结果有问题。不信可以试试
//        float lastwidth = size.width;
//        float lastheight = size.height;
        
//        NSString * widthStr = [NSString stringWithFormat:@"%.2f", lastwidth];
//        NSString * heightStr = [NSString stringWithFormat:@"%.2f", lastheight];
//        float widthFrame = [widthStr floatValue];
//        float heightFrame = [heightStr floatValue];
        
//        float widthFrame = roundf(lastwidth*100)/100;
//        float heightFrame = roundf(lastheight*100)/100;
        
        if(!isAutoWidth)
            lastwidth = _model.RealWidth;
        if(!isAutoHeight)
            lastheight = _model.RealHeight;
        self.frame = CGRectMake(_model.RealX, _model.RealY, lastwidth, lastheight);
        
        //实现布局相关的修改
        [doUIModuleHelper OnResize:_model];
        
        [doUIModuleHelper generateBorder:_model :[_model GetPropertyValue:@"border"]];
    }else {
        
        [doUIModuleHelper OnRedraw:_model];
        //修改label的frame，frame的height是double型，top会产生黑色边框
        CGRect frame = self.frame;
        frame.size = CGSizeMake(frame.size.width, (int)(_model.RealHeight));
        self.frame = frame;
    }
}

- (BOOL)isAutoHeight
{
    return [[_model GetPropertyValue:@"height"] isEqualToString:@"-1"];
}

- (BOOL)isAutoWidth
{
    return [[_model GetPropertyValue:@"width"] isEqualToString:@"-1"];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */

- (void)change_shadow:(NSString *)newValue
{
    _myShadow = newValue;
    NSArray * _arrays = [newValue componentsSeparatedByString:@","];
    if (_arrays.count < 4) {
        return;
    }
    
    NSString * shadowColor = [_arrays objectAtIndex:0];
    if ([[_arrays objectAtIndex:0] isEqualToString:@""] || [_arrays objectAtIndex:0] == nil) {
        shadowColor = @"000000FF";
    }
    CGFloat x = [[_arrays objectAtIndex:1] floatValue]*_model.XZoom;
    if ([[_arrays objectAtIndex:1] isEqualToString:@""] || [_arrays objectAtIndex:1] == nil) {
        x = 0;
    }
    CGFloat y = [[_arrays objectAtIndex:2] floatValue]*_model.YZoom;
    if ([[_arrays objectAtIndex:2] isEqualToString:@""] || [_arrays objectAtIndex:2] == nil) {
        y = 0;
    }
    CGFloat radius = [[_arrays objectAtIndex:3] floatValue]*(_model.XZoom+_model.YZoom)/2;
    if ([[_arrays objectAtIndex:3] isEqualToString:@""] || [_arrays objectAtIndex:3] == nil) {
        radius =0;
    }
    
    //android端radius=0时,没有阴影；iOS端radiu=0时，有阴影没有模糊特效。配合安卓端设为0；
    if (radius == 0) {
        
        NSMutableAttributedString *content = [self.attributedText mutableCopy];
        [content beginEditing];
        NSRange contentRange = {0,[content length]};
        [content removeAttribute:NSShadowAttributeName range:contentRange];
        [content endEditing];
        self.attributedText = content;
        
        return;
    } else {
        NSShadow * shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = radius;
        shadow.shadowOffset = CGSizeMake(x, y);
        shadow.shadowColor = [doUIModuleHelper GetColorFromString:shadowColor :[doUIModuleHelper GetColorFromString:_fontColor :[UIColor blackColor]]];
        
        NSMutableAttributedString * content = [self.attributedText mutableCopy];
        [content beginEditing];
        NSRange contentRange = {0,[content length]};
        [content removeAttribute:NSForegroundColorAttributeName range:contentRange];
        
        //text保持原来的color
        UIColor *color = [doUIModuleHelper GetColorFromString:_fontColor :[UIColor blackColor]];
        [content addAttribute:NSForegroundColorAttributeName value:color range:contentRange];

        [content addAttribute:NSShadowAttributeName
                        value:shadow
                        range:contentRange];
        [content endEditing];
        self.attributedText = content;
    }
    
}
- (void)change_text:(NSString *)newValue
{
    newText = newValue;
    [self setText:newValue];
    [self setContentStyle];
}
- (void)change_fontColor:(NSString *)newValue
{
    _fontColor = newValue;

    UIColor *color = [doUIModuleHelper GetColorFromString:newValue :[UIColor blackColor]];
    
    NSMutableAttributedString *content = [self.attributedText mutableCopy];
    [content beginEditing];
    NSRange contentRange = {0,[content length]};
    [content removeAttribute:NSForegroundColorAttributeName range:contentRange];
    [content addAttribute:NSForegroundColorAttributeName value:color range:contentRange];
    
    [content endEditing];
    self.attributedText = content;
}

- (void)change_textFlag:(NSString *)newValue
{
    //自己的代码实现
    _myFontFlag = [NSString stringWithFormat:@"%@",newValue];
    if (!IOS_8 && _intFontSize < 14) {
        return;
    }
    if (self.text==nil || [self.text isEqualToString:@""]) return;
    
    NSMutableAttributedString *content = [self.attributedText mutableCopy];
    [content beginEditing];
    NSRange contentRange = {0,[content length]};
    [content removeAttribute:NSUnderlineStyleAttributeName range:contentRange];
    [content removeAttribute:NSStrikethroughStyleAttributeName range:contentRange];
    if ([newValue isEqualToString:@"normal" ]) {
        
    }else if ([newValue isEqualToString:@"underline" ]) {
        [content addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:contentRange];
    }else if ([newValue isEqualToString:@"strikethrough" ]) {
//        [content addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:contentRange];
        //iOS10.3系统bug，label富文本不显示删除线
        [content addAttributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle], NSBaselineOffsetAttributeName:@(NSUnderlineStyleSingle)} range:contentRange];
        
    }
    [content endEditing];
    self.attributedText = content;
}
- (void)change_fontStyle:(NSString *)newValue
{
    //自己的代码实现
    _myFontStyle = [NSString stringWithFormat:@"%@",newValue];
    if (self.text==nil || [self.text isEqualToString:@""]) return;
    
    float fontSize = self.font.pointSize;
    if([newValue isEqualToString:@"normal"])
        [self setFont:[UIFont systemFontOfSize:fontSize]];
    else if([newValue isEqualToString:@"bold"])
        [self setFont:[UIFont boldSystemFontOfSize:fontSize]];
    else if([newValue isEqualToString:@"italic"])
    {
        CGAffineTransform matrix =  CGAffineTransformMake(1, 0, tanf(FONT_OBLIQUITY * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor *desc = [ UIFontDescriptor fontDescriptorWithName :[ UIFont systemFontOfSize :fontSize ]. fontName matrix :matrix];
        [self setFont:[ UIFont fontWithDescriptor :desc size :fontSize]];
    }
    else if([newValue isEqualToString:@"bold_italic"]){}
}
- (void)change_fontSize:(NSString *)newValue
{
    _intFontSize = [doUIModuleHelper GetDeviceFontSize:[[doTextHelper Instance] StrToInt:newValue :[[_model GetProperty:@"fontSize"].DefaultValue intValue]] :_model.XZoom :_model.YZoom];
    self.font = [UIFont systemFontOfSize:_intFontSize];
    
    if(_myFontStyle)
        [self change_fontStyle:_myFontStyle];
    if (_myFontFlag)
        [self change_textFlag:_myFontFlag];
}
- (void)setCustomFont:(UIFont *)font
{
    NSMutableAttributedString *content = [self.attributedText mutableCopy];
    [content beginEditing];
    NSRange contentRange = {0,[content length]};
    [content removeAttribute:NSFontAttributeName range:contentRange];
    [content addAttribute:NSFontAttributeName value:font range:contentRange];
    
    [content endEditing];
    self.attributedText = content;
}
- (void)change_textAlign:(NSString *)newValue
{
    _myTextAlign = newValue;
    NSTextAlignment alignment = NSTextAlignmentLeft;

    if([newValue isEqualToString:@"left"])
        alignment = NSTextAlignmentLeft;
    else if([newValue isEqualToString:@"center"])
        alignment = NSTextAlignmentCenter;
    else if([newValue isEqualToString:@"right"])
        alignment = NSTextAlignmentRight;
    
    NSMutableAttributedString *content = [self.attributedText mutableCopy];
    [content beginEditing];
    NSRange contentRange = {0,[content length]};
    [content removeAttribute:NSParagraphStyleAttributeName range:contentRange];

    _paragraphStyle.alignment = alignment;
    [content addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle range:contentRange];
    
    [content endEditing];

    self.attributedText = content;

}
- (void)change_maxWidth:(NSString *)newValue
{
    if([newValue floatValue] > 0)
    {
        maxWidth = [newValue floatValue]*_model.XZoom;
    }else{
        maxWidth = 0;
    }
}
- (void)change_maxHeight:(NSString *)newValue
{
    if([newValue floatValue] > 0)
    {
        maxHeight = [newValue floatValue]*_model.YZoom;
    }else{
        maxHeight = 0;
    }
}
- (void)change_maxLines:(NSString *)newValue
{
    NSInteger number = [newValue integerValue];
    if(number < 0)
        number =0;
    self.numberOfLines = number;

    NSMutableAttributedString *content = [self.attributedText mutableCopy];

    [content beginEditing];
    NSRange contentRange = {0,[content length]};
    [content removeAttribute:NSParagraphStyleAttributeName range:contentRange];

    if (![self isAutoWidth] && ![self isAutoHeight]) {
        _paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    }else
        _paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    [content addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle range:contentRange];
    
    [content endEditing];
    self.attributedText = content;

}
- (void)change_linesSpace:(NSString *)newValue
{
    _linesSpace = [newValue intValue];
    if (_linesSpace<0) {
        _linesSpace = 0;
    }else if (_linesSpace>100) {
        _linesSpace = 100;
    }
    
    _linesSpace = _linesSpace*_model.YZoom;

    if (newText.length>0) {
        [self change_text:newText];
    }
}

- (void)setContentStyle
{
    if(_myFontStyle)
        [self change_fontStyle:_myFontStyle];
    if (_myFontFlag)
        [self change_textFlag:_myFontFlag];
    if (_myTextAlign) {
        [self change_textAlign:_myTextAlign];
    }
    if (_fontColor) {
        [self change_fontColor:_fontColor];
    }
    if (_myShadow) {
        [self change_shadow:_myShadow];
    }
 
    NSMutableAttributedString *content = [self.attributedText mutableCopy];
    [content beginEditing];
    NSRange contentRange = {0,[content length]};
    [content removeAttribute:NSParagraphStyleAttributeName range:contentRange];
    
    _paragraphStyle.lineSpacing = _linesSpace;
    [content addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle range:contentRange];
    
    [content endEditing];
    self.attributedText = content;
    
    [self setNeedsDisplay];
}
#pragma mark - private

- (CGSize)autoSize:(CGFloat)width :(CGFloat)height
{
    NSAttributedString *text = self.attributedText;
    if(text == nil || text.length==0) return CGSizeMake(0, 0);

    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithAttributedString:text];

    NSRange allRange = {0,[text length]};
    [attrStr addAttribute:NSFontAttributeName
                    value:self.font
                    range:allRange];
    [attrStr addAttribute:NSForegroundColorAttributeName
                    value:self.textColor
                    range:allRange];

    NSStringDrawingOptions options =  NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine;
    CGRect rect = [attrStr boundingRectWithSize:CGSizeMake(width, height)
                                        options:options
                                        context:nil];
    CGFloat widthR = CGRectGetWidth(rect);
    CGFloat heightR = ceilf(CGRectGetHeight(rect)) + 2;// 加两个像素,防止emoji被切掉.
    
    if (widthR >= width) {
        widthR = width;
    }
    if (heightR >= height) {
        heightR = height;
    }
    return CGSizeMake(widthR,heightR);
}
//修改listview 的cell被选中的时候，背景色自动变为白色问题
- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    UIColor *bgColor = [doUIModuleHelper GetColorFromString:[_model GetPropertyValue:@"bgColor"] : [UIColor clearColor]];
    if (CGColorEqualToColor(bgColor.CGColor,backgroundColor.CGColor)) {
        [super setBackgroundColor:bgColor];
    }
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
    if([_changedValues.allKeys containsObject:@"text"]||[_changedValues.allKeys containsObject:@"fontSize"]||[_changedValues.allKeys containsObject:@"fontStyle"]||[_changedValues.allKeys containsObject:@"fontSize"]||[_changedValues.allKeys containsObject:@"maxWidth"]||[_changedValues.allKeys containsObject:@"maxHeight"])
    {
        BOOL isAutoHeight = [[_model GetPropertyValue:@"height"] isEqualToString:@"-1"];
        BOOL isAutoWidth = [[_model GetPropertyValue:@"width"] isEqualToString:@"-1"];
        if(isAutoHeight||isAutoWidth)
        {
            [self OnRedraw];
        }
    }
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
