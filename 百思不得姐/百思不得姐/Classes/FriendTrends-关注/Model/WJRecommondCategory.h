//
//  WJRecommondCategory.h
//  百思不得姐
//
//  Created by wangju on 16/3/16.
//  Copyright © 2016年 wangju. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WJRecommondCategory : NSObject

/*总数*/
@property (nonatomic,assign) NSInteger count;

/*id*/
@property (nonatomic,assign) NSInteger id;

/*名称*/
@property (nonatomic,copy) NSString *name;


/*该条目的用户数据*/
@property (nonatomic,strong) NSMutableArray *users;

/*下一页*/
@property (nonatomic,assign) NSInteger next_page;

/*总页数*/
@property (nonatomic,assign) NSInteger total_page;

@end
