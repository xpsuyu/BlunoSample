//
//  VCMain.m
//  SimpleSample
//
//  Created by Seifer on 13-10-15.
//  Copyright (c) 2013年 DFRobot. All rights reserved.
//

#import "VCMain.h"
#import "BLEUtility.h"
#import <Foundation/NSRange.h>

#define kMaxLength 88
#define kMinLength 40

@interface VCMain ()
{
    BOOL _bCentralPowerOn;
    BOOL _bCanMoveColorSelector;
    UIImage* _imgTest;
    enum TabState _tabState;
    BOOL _bLedOpened;
    BOOL _bConnected;
    NSInteger _nInputViewOriginY;//记录输入框所在视图的原始Y坐标值，用于处理视图随键盘出现并移动。
}

@end

@implementation VCMain

#pragma mark - keyboard up and down

- (void)addKeyboardEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardEvents
{

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    
    self.btnComplete.hidden = NO;
    NSDictionary *userInfo = [notification userInfo];
    
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardRect = [aValue CGRectValue];
    
    CGFloat keyboardTop = keyboardRect.size.height;
    CGRect newTextViewFrame = self.view.frame;
    newTextViewFrame.origin.y = _nInputViewOriginY - keyboardTop;
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    self.view.frame = newTextViewFrame;
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    [self.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    [UIView commitAnimations];

}


#pragma mark- Functions

- (void)writeMessage:(NSString*)msg
{
    if (!_bConnected)
    {
        return;
    }

    NSData* bytes = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [self.blunoManager writeDataToDevice:bytes Device:self.blunoDev];

}


-(void) ledSwitch
{

    if (_bLedOpened)
    {
        _bLedOpened = NO;
        self.imgviewLedColor.image = [UIImage imageNamed:@"1_4_LED_OFF.png"];
        if (_bConnected)
        {
            [self writeMessage:[NSString stringWithFormat:@"<RGBLED>0,0,0;"]];
        }
        
    }
    else
    {
        _bLedOpened = YES;
        self.imgviewLedColor.image = [UIImage imageNamed:@"1_4_LED.png"];
    }
}

-(void) callTemp
{
    if (_bConnected)
    {
        [self writeMessage:@"<TEMP>;"];
    }
    
    [self performSelector:@selector(callTemp) withObject:Nil afterDelay:1];
}

-(void) callHum
{
    if (_bConnected)
    {
        [self writeMessage:@"<HUMID>;"];
    }
    
    [self performSelector:@selector(callHum) withObject:Nil afterDelay:1];
}
-(void) callPot
{
    if (_tabState == POT)
    {
        if (_bConnected)
        {
            [self writeMessage:@"<KNOB>;"];
        }
        
        [self performSelector:@selector(callPot) withObject:Nil afterDelay:0.4];
    }
}
-(void) callRocker
{
    if (_tabState == ROCKER)
    {
        if (_bConnected)
        {
            [self writeMessage:@"<ROCKER>;"];
        }
        
        [self performSelector:@selector(callRocker) withObject:Nil afterDelay:0.2];
    }
}

-(void) callLed
{
    if (_tabState == LED)
    {
        if (_bLedOpened && _bConnected)
        {
            int convertX = (596/self.viewPicker.frame.size.width)*self.imgviewPoint.center.x;
            int convertY = (448/self.viewPicker.frame.size.height)*self.imgviewPoint.center.y;
            NSArray* aryColor = [self getRGBAsFromImage:_imgTest X:convertX Y:convertY Count:1];
            UIColor* color = [aryColor objectAtIndex:0];
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            CGFloat alpha;
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            int nRed = (int)(red*255);
            int nGreen =(int)(green*255);
            int nBlue = (int)(blue*255);
            [self writeMessage:[NSString stringWithFormat:@"<RGBLED>%d,%d,%d;",nRed,nGreen,nBlue]];
        }
        
        [self performSelector:@selector(callLed) withObject:Nil afterDelay:0.4];
    }
}

-(void) showPot:(NSString*) strNum
{
    float amount = 1023.0;
    float num = [strNum intValue];
    float percent = num/amount;
    float maxAngle = 360-(135-45);
    float curAngel = 135 + maxAngle * percent;
    
    UIGraphicsBeginImageContext(self.imgviewPotmeter.frame.size);
    [self.imgviewPotmeter drawRect:CGRectMake(0, 0, self.imgviewPotmeter.frame.size.width, self.imgviewPotmeter.frame.size.height)];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.imgviewPotmeter.frame);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetRGBStrokeColor(context, 63/255.0, 233/255.0, 194/255.0, 1);//改变画笔颜色
    CGContextSetLineWidth(context, 5.0);
    //CGContextAddArc ( context, 137, 120, 80, (135/360.0)*2*3.14, (45/360.0)*2*3.14,0);//角度是顺时针为正向，水平为0度。
    CGContextAddArc ( context, 137, 100, 82, (135/360.0)*2*3.14, (curAngel/360.0)*2*3.14,0);//角度是顺时针为正向，水平为0度。
    CGContextStrokePath(context);//绘画路径
    self.imgviewPotmeter.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
}

-(void) showRocker:(NSString*)strNum
{
    if ([strNum isEqualToString:@"0"])
    {
        self.imgviewRocker.image = [UIImage imageNamed:@"1_2_AllButton.png"];
    }
    else if ([strNum isEqualToString:@"1"])
    {
        self.imgviewRocker.image = [UIImage imageNamed:@"1_2_ButtonRight.png"];
    }
    else if ([strNum isEqualToString:@"2"])
    {
        self.imgviewRocker.image = [UIImage imageNamed:@"1_2_ButtonUp.png"];
    }
    else if ([strNum isEqualToString:@"3"])
    {
        self.imgviewRocker.image = [UIImage imageNamed:@"1_2_ButtonLeft.png"];
    }
    else if ([strNum isEqualToString:@"4"])
    {
        self.imgviewRocker.image = [UIImage imageNamed:@"1_2_ButtonDown.png"];
    }
    else if ([strNum isEqualToString:@"5"])
    {
        self.imgviewRocker.image = [UIImage imageNamed:@"1_2_ButtonCenter.png"];
    }

}

-(void) showTemp:(NSString*)temp
{
    self.lbTemp.text = [NSString stringWithFormat:@"%@°C",temp];
}

-(void) showHum:(NSString*)hum
{
    self.lbHum.text = [NSString stringWithFormat:@"%@%%",hum];
}

- (NSArray*)getRGBAsFromImage:(UIImage*)image X:(int)x Y:(int)y Count:(int)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    int byteIndex = (int)((bytesPerRow * y) + x * bytesPerPixel);
    for (int ii = 0 ; ii < count ; ++ii)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        
        UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [result addObject:acolor];
    }
    
    free(rawData);
    
    return result;
}

#pragma mark- Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.blunoManager = [DFBlunoManager sharedInstance];
    self.blunoManager.delegate = self;
    self.aryDevices = [[NSMutableArray alloc] init];
    
    _tabState = LED;
    _bConnected = NO;
    _bCentralPowerOn = NO;
    _bCanMoveColorSelector = NO;
    _bLedOpened = NO;
    _imgTest = [UIImage imageNamed:@"1_4_LED.png"];

    CGSize rect = ((UIWindow*)[[UIApplication sharedApplication].windows objectAtIndex:0]).frame.size;
    if (rect.height == 480)
    {
        self.viewMainFrame.frame = CGRectMake(0, 0, 320, 480);
    }
    else
    {
        self.viewMainFrame.frame = CGRectMake(0, 0, 320, 568);
        self.txtMessage.frame = CGRectMake(self.txtMessage.frame.origin.x, self.txtMessage.frame.origin.y, self.txtMessage.frame.size.width, self.txtMessage.frame.size.height+88);
        self.btnClear.center = CGPointMake(self.btnClear.center.x, self.btnClear.center.y+88);
        self.btnSubmit.center = CGPointMake(self.btnSubmit.center.x, self.btnSubmit.center.y+88);
        
    }
    _nInputViewOriginY = self.view.frame.origin.y;
    
    //self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.viewPicker.delegate = self;
    self.aryMessages = [[NSMutableArray alloc] init];
    self.stickCenterPoint = [[Vector2 alloc] initWithV1:136 V2:100];
    
    self.btnLed.selected = YES;
    self.viewMask.hidden = NO;
    [self addKeyboardEvents];

    [self callHum];
    [self callTemp];
    switch (_tabState)
    {
        case LED:
            [self callLed];
            break;
        case ROCKER:
            [self callRocker];
            break;
        case POT:
            [self callPot];
            break;
        default:
            break;
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions


- (IBAction)actionLed:(id)sender
{
    if (_tabState == LED)
    {
        return;
    }
    _tabState = LED;
    self.btnLed.selected = YES;
    self.btnJoy.selected = NO;
    self.btnPot.selected = NO;
    self.viewLed.hidden = NO;
    self.viewJoy.hidden = YES;
    self.viewPot.hidden = YES;
    [self callLed];
}

- (IBAction)actionJoy:(id)sender
{
    if (_tabState == ROCKER)
    {
        return;
    }
    _tabState = ROCKER;
    self.btnLed.selected = NO;
    self.btnJoy.selected = YES;
    self.btnPot.selected = NO;
    self.viewLed.hidden = YES;
    self.viewJoy.hidden = NO;
    self.viewPot.hidden = YES;
    [self callRocker];
}

- (IBAction)actionPot:(id)sender
{
    if (_tabState == POT)
    {
        return;
    }
    _tabState = POT;
    self.btnLed.selected = NO;
    self.btnJoy.selected = NO;
    self.btnPot.selected = YES;
    self.viewLed.hidden = YES;
    self.viewJoy.hidden = YES;
    self.viewPot.hidden = NO;
    [self callPot];
    
}

- (IBAction)actionBuzzer:(id)sender
{
    ((UIButton*)sender).selected = !((UIButton*)sender).selected;
    NSString* strTemp = ((UIButton*)sender).selected ? @"<BUZZER>1;":@"<BUZZER>0;";

    if (_bConnected)
    {
        [self writeMessage:strTemp];
    }

}

- (IBAction)actionRelay:(id)sender
{
    ((UIButton*)sender).selected = !((UIButton*)sender).selected;
    NSString* strTemp = ((UIButton*)sender).selected ? @"<RELAY>1;":@"<RELAY>0;";
    if (_bConnected)
    {
        [self writeMessage:strTemp];
    }

}

- (IBAction)actionComplete:(id)sender
{
    [self.txtMessage resignFirstResponder];
    self.btnComplete.hidden = YES;
}

- (IBAction)actionSubmit:(id)sender
{
    NSString* strText = [NSString stringWithFormat:@"<DISP%@>;",self.txtMessage.text];
    if (_bConnected)
    {
        int nLength = (int)strText.length;
        int nCount = nLength/18;
        int nMod = nLength%18;
        for (int i=0; i<nCount; i++)
        {
            NSRange range;
            range.location = i*18;
            range.length = 18;
            NSString* strTemp = [strText substringWithRange:range];
            [self writeMessage:strTemp];
        }
        if (nMod>0)
        {
            NSRange range;
            range.location = nCount*18;
            range.length = nMod;
            NSString* strTemp = [strText substringWithRange:range];
            [self writeMessage:strTemp];
        }
        
    }
}

- (IBAction)actionClear:(id)sender
{
    self.txtMessage.text = @"";

}

- (IBAction)actionReturn:(id)sender
{
    [self.SearchIndicator stopAnimating];
    [self.blunoManager stop];
    self.viewDevices.hidden = YES;
}

- (IBAction)actionSearch:(id)sender
{
    [self.aryDevices removeAllObjects];
    [self.tbDevices reloadData];
    [self.SearchIndicator startAnimating];
    self.viewDevices.hidden = NO;
    
    [self.blunoManager scan];
}

#pragma mark- DFBlunoDelegate

-(void)bleDidUpdateState:(BOOL)bleSupported
{
    if(bleSupported)
    {
        _bCentralPowerOn = YES;
    }
    else
    {
        _bCentralPowerOn = NO;
    }
}
-(void)didDiscoverDevice:(DFBlunoDevice*)dev
{
    //[self.blunoManager connectToDevice:dev];
    //self.blunoDev = dev;
    BOOL bRepeat = NO;
    for (DFBlunoDevice* bleDevice in self.aryDevices)
    {
        if ([bleDevice isEqual:dev])
        {
            bRepeat = YES;
            break;
        }
    }
    if (!bRepeat)
    {
        [self.aryDevices addObject:dev];
    }
    [self.tbDevices reloadData];
}
-(void)readyToCommunicate:(DFBlunoDevice*)dev
{
    self.blunoDev = dev;
    _bConnected = YES;
    //self.imgviewTitle.image = [UIImage imageNamed:@"1_5_connected.png"];
    
    self.viewMask.hidden = YES;
    
}
-(void)didDisconnectDevice:(DFBlunoDevice*)dev
{
    _bConnected = NO;

    //self.imgviewTitle.image = [UIImage imageNamed:@"1_5_connecting.png"];
    self.viewMask.hidden = NO;

}
-(void)didWriteData:(DFBlunoDevice*)dev
{
    
}
-(void)didReceiveData:(NSData*)data Device:(DFBlunoDevice*)dev
{
    
        
    NSString *strOri = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
    NSArray *aryOri = [strOri componentsSeparatedByString:@";"];
    //int a = [aryOri count];
    if ([aryOri count] <= 1)
    {
        return;
    }
    NSString *strFirst = [aryOri objectAtIndex:0];
    
    NSArray *aryAfter = [strFirst componentsSeparatedByString:@">"];
    if ([aryAfter count] <= 1)
    {
        return;
    }
    NSString *strSecond = [aryAfter objectAtIndex:0];
    if ([strSecond isEqualToString:@"<ROCKER"])
    {
        
        NSString* strNum = [aryAfter objectAtIndex:1];
        [self showRocker:strNum];
        
    }
    else if ([strSecond isEqualToString:@"<TEMP"])
    {
        NSString* strTemp = [aryAfter objectAtIndex:1];
        [self showTemp:strTemp];
    }
    else if ([strSecond isEqualToString:@"<HUMID"])
    {
        NSString* strHum = [aryAfter objectAtIndex:1];
        [self showHum:strHum];
    }
    else if ([strSecond isEqualToString:@"<KNOB"])
    {
        NSString* strNum = [aryAfter objectAtIndex:1];
        [self showPot:strNum];
    }

}


#pragma mark- Custom View Delegate

- (void)CustomViewTouchesBeganPoints:(CGPoint*)points Count:(int)count  WhichView:(id)customView
{
    if (customView == self.viewPicker)
    {
        CGPoint p0 = CGPointMake(points[0].x, points[0].y);
        Vector2* v1 = [[Vector2 alloc] initWithV1:p0.x V2:p0.y];
        double lenght = [v1 getLengthFromVector:self.stickCenterPoint];

        if(lenght < kMinLength)
        {
            [self ledSwitch];
        }
        if (lenght < kMaxLength && lenght > kMinLength)
        {
            _bCanMoveColorSelector = YES;
            self.imgviewPoint.center = points[0];
            self.currentStickPoint = v1;
            
        }
        else
        {
            _bCanMoveColorSelector = NO;
        }
        
        
    }
}
- (void)CustomViewTouchesMovedPoints:(CGPoint*)points Count:(int)count  WhichView:(id)customView
{
    if (customView == self.viewPicker && _bCanMoveColorSelector)
    {
        CGPoint p0 = CGPointMake(points[0].x, points[0].y);
        Vector2* v1 = [[Vector2 alloc] initWithV1:p0.x V2:p0.y];
        double lenght = [v1 getLengthFromVector:self.stickCenterPoint];
        if (lenght > kMaxLength)
        {
            v1 = [v1 subVector2:self.stickCenterPoint];
            [v1 normalize];
            v1 = [v1 multiplyNum:kMaxLength];
            Vector2* v2 = [v1 addVector2:self.stickCenterPoint];
            self.imgviewPoint.center = CGPointMake(v2.x, v2.y);
            self.currentStickPoint = v2;
        }
        else if(lenght < kMinLength)
        {
            v1 = [v1 subVector2:self.stickCenterPoint];
            [v1 normalize];
            v1 = [v1 multiplyNum:kMinLength];
            Vector2* v2 = [v1 addVector2:self.stickCenterPoint];
            self.imgviewPoint.center = CGPointMake(v2.x, v2.y);
            self.currentStickPoint = v2;
        }
        else
        {
            self.imgviewPoint.center = points[0];
            self.currentStickPoint = v1;
            
        }

    }

}
- (void)CustomViewTouchesEndedPoints:(CGPoint*)points Count:(int)count  WhichView:(id)customView
{
    _bCanMoveColorSelector = NO;
}


#pragma mark- TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger nCount = [self.aryDevices count];
    return nCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"ScanDeviceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            [[NSBundle mainBundle] loadNibNamed:@"CellDeviceList" owner:self options:nil];
        }
        else
        {
            
        }
        
        cell = self.cellDevices;
	}
    
    UILabel* lbName             = (UILabel*)[cell viewWithTag:1];
    UILabel* lbUUID             = (UILabel*)[cell viewWithTag:2];
    DFBlunoDevice* peripheral   = [self.aryDevices objectAtIndex:indexPath.row];
    
    lbName.text = peripheral.name;
    lbUUID.text = peripheral.identifier;
    
    return cell;
    
}


#pragma mark- TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DFBlunoDevice* device = [self.aryDevices objectAtIndex:indexPath.row];
    if (self.blunoDev == nil)
    {
        self.blunoDev = device;
        [self.blunoManager connectToDevice:self.blunoDev];
    }
    else if ([device isEqual:self.blunoDev])
    {
        if (!self.blunoDev.bReadyToWrite)
        {
            [self.blunoManager connectToDevice:self.blunoDev];
        }
    }
    else
    {
        if (self.blunoDev.bReadyToWrite)
        {
            [self.blunoManager disconnectToDevice:self.blunoDev];
            self.blunoDev = nil;
        }
        
        [self.blunoManager connectToDevice:device];
    }
    self.viewDevices.hidden = YES;
    [self.SearchIndicator stopAnimating];
}


@end
