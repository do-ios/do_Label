//
//  do_Label_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_Label_IView.h"
#import "do_Label_UIModel.h"
#import "doIUIModuleView.h"

@interface do_Label_UIView : UILabel<do_Label_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_Label_UIModel *_model;
}

@end
