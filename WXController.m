//
//  WXController.m
//  SimpleWeather
//
//  Created by Ryan Nystrom on 11/11/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//

#import "WXController.h"
#import <LBBlurredImage/UIImageView+LBBlurredImage.h>

#import "WXManager.h"

@interface WXController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *blurredImageView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat screenHeight;

@property (nonatomic, strong) NSDateFormatter *hourlyFormatter;
@property (nonatomic, strong) NSDateFormatter *dailyFormatter;
@end

@implementation WXController

//由于创建日期格式化非常昂贵，我们将在init方法中实例化他们，并使用这些变量去存储他们的引用。
//实际上-viewDidLoad可以在一个视图控制器的生命周期中多次调用。 NSDateFormatter对象的初始化是昂贵的，而将它们放置在你的-init，会确保被你的视图控制器初始化一次。
- (instancetype)init
{
    self = [super init];
    if (self) {

        _hourlyFormatter = [[NSDateFormatter alloc] init];
        _hourlyFormatter.dateFormat = @"h a";
        
        _dailyFormatter = [[NSDateFormatter alloc] init];
        _dailyFormatter.dateFormat = @"EEEE";
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIImage *background = [UIImage imageNamed:@"bg"];
    
    self.backgroundImageView = [[UIImageView alloc] initWithImage:background];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];
    
    self.blurredImageView = [[UIImageView alloc] init];
    self.blurredImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.blurredImageView.alpha = 0;
    [self.blurredImageView setImageToBlur:background blurRadius:10 completionBlock:nil];
    [self.view addSubview:self.blurredImageView];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.tableView.pagingEnabled = YES;
    [self.view addSubview:self.tableView];
    
    CGRect headerFrame = [UIScreen mainScreen].bounds;
    CGFloat inset = 20;
    CGFloat temperatureHeight = 110;
    CGFloat hiloHeight = 40;
    CGFloat iconHeight = 30;
    CGRect hiloFrame = CGRectMake(inset, headerFrame.size.height - hiloHeight, headerFrame.size.width - 2*inset, hiloHeight);
    CGRect temperatureFrame = CGRectMake(inset, headerFrame.size.height - temperatureHeight - hiloHeight, headerFrame.size.width - 2*inset, temperatureHeight);
    CGRect iconFrame = CGRectMake(inset, temperatureFrame.origin.y - iconHeight, iconHeight, iconHeight);
    CGRect conditionsFrame = iconFrame;
    // make the conditions text a little smaller than the view
    // and to the right of our icon
    conditionsFrame.size.width = self.view.bounds.size.width - 2*inset - iconHeight - 10;
    conditionsFrame.origin.x = iconFrame.origin.x + iconHeight + 10;
    
    UIView *header = [[UIView alloc] initWithFrame:headerFrame];
    header.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = header;
    
	// bottom left
    UILabel *temperatureLabel = [[UILabel alloc] initWithFrame:temperatureFrame];
    temperatureLabel.backgroundColor = [UIColor clearColor];
    temperatureLabel.textColor = [UIColor whiteColor];
    temperatureLabel.text = @"0°";
    temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:120];
    [header addSubview:temperatureLabel];
    
    // bottom left
    UILabel *hiloLabel = [[UILabel alloc] initWithFrame:hiloFrame];
    hiloLabel.backgroundColor = [UIColor clearColor];
    hiloLabel.textColor = [UIColor whiteColor];
    hiloLabel.text = @"0° / 0°";
    hiloLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28];
    [header addSubview:hiloLabel];
    
    // top
    UILabel *cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 30)];
    cityLabel.backgroundColor = [UIColor clearColor];
    cityLabel.textColor = [UIColor whiteColor];
    cityLabel.text = @"Loading...";
    cityLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cityLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:cityLabel];
    
    UILabel *conditionsLabel = [[UILabel alloc] initWithFrame:conditionsFrame];
    conditionsLabel.backgroundColor = [UIColor clearColor];
    conditionsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    conditionsLabel.textColor = [UIColor whiteColor];
    [header addSubview:conditionsLabel];
    
    // bottom left
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:iconFrame];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    [header addSubview:iconView];
    

    [[WXManager sharedManager] findCurrentLocation];
    
    //1.观察WXManager单例的currentCondition。
    [[RACObserve([WXManager sharedManager], currentCondition)
      //2.传递在主线程上的任何变化，因为你正在更新UI。
      deliverOn:
      [RACScheduler mainThreadScheduler]] subscribeNext:^(WXCondition *newCondition) {
        //3.使用气象数据更新文本标签；你为文本标签使用newCondition的数据，而不是单例。订阅者的参数保证是最新值。
        temperatureLabel.text = [NSString stringWithFormat:@"%.0f°", newCondition.temperature.floatValue];
        conditionsLabel.text = [newCondition.condition capitalizedString];
        cityLabel.text = [newCondition.locationName capitalizedString];
        //4.使用映射的图像文件名来创建一个图像，并将其设置为视图的图标。
        iconView.image = [UIImage imageNamed:[newCondition imageName]];
    }];
    
    
    //1.在RAC （ ... ）宏有助于保持语法干净。从该信号的返回值被分配给 hiloLabel对象的文本项。
     RAC(hiloLabel, text) = [[RACSignal combineLatest:@[
                                                       //2.观察了高温和低温的currentCondition key。
                                                       RACObserve([WXManager sharedManager], currentCondition.tempHigh),
                                                       RACObserve([WXManager sharedManager], currentCondition.tempLow)
                                                       //3.降低您的组合信号的值转换成一个单一的值，注意该参数的顺序信号的顺序相匹配。
                                                       ] reduce:^(NSNumber *hi, NSNumber *low) {
                                                           return [NSString stringWithFormat:@"%.0f°/%.0f°", hi.floatValue, low.floatValue];
                                                           //4.同样，因为你正在处理UI界面，所以把所有东西都传递到主线程。
                                                       }] deliverOn:[RACScheduler mainThreadScheduler]];
    
    /*如果你已经使用过的UITableView，可能你之前遇到过问题。这个table没有重新加载！
    
    为了解决这个问题，你需要添加另一个针对每时预报和每日预报属性的ReactiveCocoa观察。
    
    在WXController.m的-viewDidLoad中，添加下列代码到其他ReactiveCocoa观察代码中：*/
    
    [[RACObserve([WXManager sharedManager], hourlyForecast) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *newForecast) {
        [self.tableView reloadData];
    }];
    
    [[RACObserve([WXManager sharedManager], dailyForecast) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *newForecast) {
        [self.tableView reloadData];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    
    self.backgroundImageView.frame = bounds;
    self.blurredImageView.frame = bounds;
    self.tableView.frame = bounds;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // TODO: Return count of forecast
//    return 0;
    //1.第一部分是对的逐时预报。使用最近6小时的预预报，并添加了一个作为页眉的单元格。
    if (section == 0) {
        return MIN([[WXManager sharedManager].hourlyForecast count], 6) +1;
    }
    //2.接下来的部分是每日预报。使用最近6天的每日预报，并添加了一个作为页眉的单元格。
    return MIN([[WXManager sharedManager].dailyForecast count], 6) +1;
}
//注意：您使用表格单元格作为标题，而不是内置的、具有粘性的滚动行为的标题。这个table view设置了分页，粘性滚动行为看起来会很奇怪。

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    
    // TODO: Setup the cell
    
    if (indexPath.section == 0) {
        //1.每个部分的第一行是标题单元格。

        if (indexPath.row == 0) {
            [self configureHeaderCell: cell title:@"Hourly Forecast"];
        }else{
            //2.获取每小时的天气和使用自定义配置方法配置cell。

            WXCondition *weather = [WXManager sharedManager].hourlyForecast[indexPath.row -1];
            [self configureHourlyCell:cell weather:weather];
        }
    }
    else if (indexPath.section == 1) {
        //1.每个部分的第一行是标题单元格。
        if (indexPath.row == 0) {
            [self configureHeaderCell:cell title:@"Daildy Forecast"];
        }else{
            //3.获取每天的天气，并使用另一个自定义配置方法配置cell。
            WXCondition *weather = [WXManager sharedManager].dailyForecast[indexPath.row -1];
            [self configureDailyCell:cell weather:weather];
        }
    }
    
    
    return cell;
}
//1.配置和添加文本到作为section页眉单元格。你会重用此为每日每时的预测部分。
- (void)configureHeaderCell: (UITableViewCell *)cell title: (NSString *)title
{
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = @"";
    cell.imageView.image = nil;
}

//2.格式化逐时预报的单元格。
- (void)configureHourlyCell: (UITableViewCell *)cell weather: (WXCondition *)weather
{
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.hourlyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f°",weather.temperature.floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}
//3.格式化每日预报的单元格。
- (void)configureDailyCell: (UITableViewCell *)cell weather: (WXCondition *)weather
{
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.dailyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f° / %.0f°",
                                 weather.tempHigh.floatValue,
                                 weather.tempLow.floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Determine cell height based on screen
//    return 44;
    NSInteger cellCount = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    return self.screenHeight / (CGFloat)cellCount;
    
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 1.获取滚动视图的高度和内容偏移量。与0偏移量做比较，因此试图滚动table低于初始位置将不会影响模糊效果。
    CGFloat height = scrollView.bounds.size.height;
    CGFloat position = MAX(scrollView.contentOffset.y, 0.0);
    // 2.偏移量除以高度，并且最大值为1，所以alpha上限为1。
    CGFloat percent = MIN(position / height, 1.0);
    // 3.当你滚动的时候，把结果值赋给模糊图像的alpha属性，来更改模糊图像。
    self.blurredImageView.alpha = percent;
}


@end
