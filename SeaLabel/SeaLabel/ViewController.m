//
//  ViewController.m
//  SeaLabel
//
//  Created by 罗海雄 on 16/9/13.
//  Copyright © 2016年 罗海雄. All rights reserved.
//

#import "ViewController.h"
#import "SeaLabel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    SeaLabel *label = [[SeaLabel alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, 100)];
    label.backgroundColor = [UIColor cyanColor];
    label.textInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    NSString *string = @"SeaLabel 测试数据 xxxxx， wwww.baidu.com，自动识别链接 点击有高亮效果，可自己设置点击的位置";
    
    label.text = string;
    [label addSelectableRange:NSMakeRange(0, 8)];
    label.selectStringHandler = ^(NSString *string){
      
        NSLog(@"点击 %@", string);
    };
    
    [self.view addSubview:label];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
