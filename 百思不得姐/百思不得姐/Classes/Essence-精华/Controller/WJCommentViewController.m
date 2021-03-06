//
//  WJCommentViewController.m
//  百思不得姐
//
//  Created by wangju on 16/4/5.
//  Copyright © 2016年 wangju. All rights reserved.
//

#import "WJCommentViewController.h"
#import "WJTopicCell.h"
#import "WJTopic.h"
#import <MJRefresh.h>
#import <AFNetworking.h>
#import <SVProgressHUD.h>
#import <MJExtension.h>
#import "WJComment.h"
#import "WJCommentHeaderView.h"
#import "WJCommentCellTableViewCell.h"


@interface WJCommentViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttomConstraint;
@property (weak, nonatomic) IBOutlet UITableView *tabbleView;

/** 记录上一次的请求参数 */
@property (nonatomic,strong) NSMutableDictionary *parmas;

/** 请求 */
@property (nonatomic,strong) AFHTTPSessionManager *manager;


/** 最热评论 */
@property (nonatomic,strong) NSMutableArray *hotComments;

/** 最新评论 */
@property (nonatomic,strong) NSMutableArray *lastComments;


/** 保存top_cmt */
@property (nonatomic,strong) NSArray *top_cmt;

/** 最后一个评论的cid */
@property (nonatomic,strong) NSString *lastcid;

@end

static NSString * const CellID = @"commentCell";

@implementation WJCommentViewController

- (NSMutableArray *)hotComments
{
    if (_hotComments == nil) {
        _hotComments = [NSMutableArray array];
    }
    return _hotComments;
}

- (NSMutableArray *)lastComments
{
    if (_lastComments == nil) {
        _lastComments = [NSMutableArray array];
    }
    return _lastComments;

}


- (AFHTTPSessionManager *)manager
{
    if (_manager == nil) {
        _manager = [AFHTTPSessionManager manager];
    }
    return _manager;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化
    [self setupBasic];
    //设置tabbleHeaderView
    [self setupTableHeaderView];
    //设置刷新控件
    [self setupRefresh];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setupBasic
{
    self.title = @"评论";
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithImage:@"comment_nav_item_share_icon" highImage:@"comment_nav_item_share_icon_click" target:nil action:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardChangedFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    self.tabbleView.backgroundColor = WJGlobalBGColor;
    
    //注册cell
    [self.tabbleView registerNib:[UINib nibWithNibName:NSStringFromClass([WJCommentCellTableViewCell class]) bundle:nil] forCellReuseIdentifier:CellID];
    
    //自动计算cell的高度
    self.tabbleView.estimatedRowHeight = 100;
    self.tabbleView.height = UITableViewAutomaticDimension;
    
    //隐藏系统分割线
    self.tabbleView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //内边距
    self.tabbleView.contentInset = UIEdgeInsetsMake(0, 0, WJTopicMargin, 0);
    
    
}

- (void)setupTableHeaderView
{
    //清空top_cmt
    self.top_cmt = self.topic.top_cmt;
    self.topic.top_cmt = nil;
    [self.topic setValue:@0 forKeyPath:@"rowHeight"];
    
    UIView *header = [[UIView alloc] init];

    WJTopicCell *topicCell = [WJTopicCell topicCell];

    [header addSubview:topicCell];

    
    topicCell.topic = self.topic;
    
    CGFloat cellW = screenSize.width;
    CGFloat cellH = self.topic.rowHeight;
    
    topicCell.size = CGSizeMake(cellW, cellH);
    
    header.height = self.topic.rowHeight;
    
    self.tabbleView.tableHeaderView = header;
    

}



- (void)setupRefresh
{
    self.tabbleView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewComments)];

    [self.tabbleView.mj_header beginRefreshing];
    
    self.tabbleView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(LoadMoreComments)];

}

- (void)loadNewComments
{
    [self.manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    
    [self.hotComments removeAllObjects];
    [self.lastComments removeAllObjects];
    [self LoadMoreComments];

}

- (void)LoadMoreComments
{
    NSMutableDictionary *parmas = [NSMutableDictionary dictionary];
    parmas[@"a"] = @"dataList";
    parmas[@"c"] = @"comment";
    parmas[@"hot"] = @1;
    parmas[@"data_id"] = @(self.topic.ID);
    WJComment *cmt = [self.lastComments lastObject];
    parmas[@"lastcid"] = cmt.id;
    self.parmas = parmas;
    
    [self.manager GET:BSURL parameters:parmas progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.tabbleView.mj_header endRefreshing];
        [self.tabbleView.mj_footer endRefreshing];

        if (![responseObject isKindOfClass:[NSDictionary class]]) return;
        NSArray *lastCommentArr = responseObject[@"data"];
        
        self.hotComments = [WJComment mj_objectArrayWithKeyValuesArray:responseObject[@"hot"]];
        
        [self.lastComments addObjectsFromArray:[WJComment mj_objectArrayWithKeyValuesArray:lastCommentArr]];
        
        self.tabbleView.mj_footer.hidden = self.lastComments.count >= [responseObject[@"total"] integerValue] || !lastCommentArr.count;
        
        
        
        if (parmas != self.parmas) return;
        
        [self.tabbleView reloadData];
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:@"加载数据失败"];
        [self.tabbleView.mj_header endRefreshing];
        [self.tabbleView.mj_footer endRefreshing];
    }];

}

- (void)keyBoardChangedFrame:(NSNotification *)noti
{

    CGRect frame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.buttomConstraint.constant = screenSize.height - frame.origin.y;
    
    
    //动画时间
    CGFloat duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
    
}

- (void)dealloc
{
    self.topic.top_cmt = self.top_cmt;
    [self.topic setValue:@0 forKeyPath:@"rowHeight"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.manager invalidateSessionCancelingTasks:YES];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //有热门评论，返回两组
    NSInteger hotCount = self.hotComments.count;
    if (hotCount) return 2;
    
    //没热门评论有最新评论，返回一组
    NSInteger lastCount = self.lastComments.count;
    if (lastCount) return 1;
    //都没有，返回0组
    return 0;
   

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self commentsInSection:section].count;
    
}

- (NSArray *)commentsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.hotComments.count ? self.hotComments : self.lastComments;
    }
    return self.lastComments;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    static NSString * const ID = @"cmt_cell";
    WJCommentCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
 
    //有热门评论，返回两组
    WJComment *comment = [self commentsInSection:indexPath.section][indexPath.row];
    
    
    cell.comment = comment;
    
    

    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    WJCommentHeaderView *header = [WJCommentHeaderView headerWithTableview:tableView];
    
    //有热门评论，返回两组
    NSInteger hotCount = self.hotComments.count;
    
    if (section == 0) {
        header.text = hotCount ? @"最热评论" : @"最新评论";
    }
    else
    {
        header.text = @"最新评论";
    }
    return header;
}




//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    //有热门评论，返回两组
//    NSInteger hotCount = self.hotComments.count;
//    
//    if (section == 0) {
//        return hotCount ? @"最热评论" : @"最新评论";
//    }
//
//    return @"最新评论";
//}



#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];

}

@end
