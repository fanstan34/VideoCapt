//
//  VideoTable.m
//  VideoCapt
//
//  Created by tangzhi on 17/4/13.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import "VideoTable.h"
#import "VedioView.h"
#define kUIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface VideoTable ()<UITableViewDelegate,UITableViewDataSource>
{
    NSMutableArray *fileAry;
}

@end

@implementation VideoTable

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    fileAry = [NSMutableArray array];
    
    NSString *docmtPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/vedio", docmtPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:createPath]) {
        NSArray *childerFiles=[fileManager subpathsAtPath:createPath];
        for (NSString *fileName in childerFiles) {
            //如有需要，加入条件，过滤掉不想删除的文件
//            NSString *absolutePath=[createPath stringByAppendingPathComponent:fileName];
            [fileAry addObject:fileName];
        }
    }
    UIView *NavGtVw = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    NavGtVw.backgroundColor = kUIColorFromRGB(0x188FEE);
    [self.view addSubview:NavGtVw];
    
    UIButton *cance = [[UIButton alloc]initWithFrame:CGRectMake(5, 30, 40, 24)];
    [cance setImage:[UIImage imageNamed:@"fanhui"] forState:UIControlStateNormal];
    [cance addTarget:self action:@selector(canceAct) forControlEvents:UIControlEventTouchUpInside];
    [NavGtVw addSubview:cance];

    
    UITableView *tbvw = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64) style:UITableViewStylePlain];
    tbvw.delegate = self;
    tbvw.dataSource = self;
    [self.view addSubview:tbvw];
    
}

- (void)canceAct {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  fileAry.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *iden = @"Vedio_cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:iden];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:iden];
    }
    cell.textLabel.text = fileAry[indexPath.row];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    __block VedioView *vdVw = [[VedioView alloc]initWithFrame:self.view.bounds];
    NSString *docmtPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/vedio", docmtPath];
    vdVw.h264FileName = [createPath stringByAppendingPathComponent:fileAry[indexPath.row]];
    [vdVw sltOprtRt:^{
        [vdVw removeFromSuperview];
        vdVw = nil;
    }];
    [self.view addSubview:vdVw];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
