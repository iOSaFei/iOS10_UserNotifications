//
//  AppDelegate.m
//  UserNotifications
//
//  Created by iOS-aFei on 16/10/11.
//  Copyright © 2016年 iOS-aFei. All rights reserved.
//

#import "AppDelegate.h"

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
//防止低版本找不到头文件出现问题

#define IOS10_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0)
#define IOS9_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)
#define IOS8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IOS7_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)


@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self replyPushNotificationAuthorization:application];
    [AppDelegate createLocalizedUserNotification];
    return YES;
}

#pragma mark - 申请通知权限
- (void)replyPushNotificationAuthorization:(UIApplication *)application{
    if (IOS10_OR_LATER) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        //必须写代理，不然无法监听通知的接收与点击事件
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!error && granted) {
                //用户点击允许
                NSLog(@"注册成功");
            }else{
                //用户点击不允许
                NSLog(@"注册失败");
            }
        }];
        
        // 可以通过 getNotificationSettingsWithCompletionHandler 获取权限设置
        //之前注册推送服务，用户点击了同意还是不同意，以及用户之后又做了怎样的更改我们都无从得知，现在 apple 开放了这个 API，我们可以直接获取到用户的设定信息了。注意UNNotificationSettings是只读对象哦，不能直接修改！
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            NSLog(@"========%@",settings);
        }];
    }else if (IOS8_OR_LATER){
        //iOS 8 - iOS 10系统
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    }else{
        //iOS 8.0系统以下
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
    
    //注册远端消息通知获取device token
    [application registerForRemoteNotifications];
}

#pragma  mark - 获取device Token
//获取DeviceToken成功
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    NSString *deviceString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceString = [deviceString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"deviceToken===========%@",deviceString);
}
//获取DeviceToken失败，模拟器无法获取
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"[DeviceToken Error]:%@\n",error.description);
}

+ (void)createLocalizedUserNotification{
    
    // 设置触发条件 UNNotificationTrigger
    UNTimeIntervalNotificationTrigger *timeTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5.0f repeats:NO];
    
    // 创建通知内容 UNMutableNotificationContent, 注意不是 UNNotificationContent ,此对象为不可变对象。
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Dely 时间提醒 - title";
    content.subtitle = [NSString stringWithFormat:@"Dely 装逼大会竞选时间提醒 - subtitle"];
    content.body = @"Dely 装逼大会总决赛时间到，欢迎你参加总决赛！希望你一统X界 - body";
    content.badge = @666;
    content.sound = [UNNotificationSound defaultSound];
    content.userInfo = @{@"key1":@"value1",@"key2":@"value2"};
    
    // 创建通知标示
    NSString *requestIdentifier = @"Dely.X.time";
    
    // 创建通知请求 UNNotificationRequest 将触发条件和通知内容添加到请求中
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestIdentifier content:content trigger:timeTrigger];
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    // 将通知请求 add 到 UNUserNotificationCenter
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"推送已添加成功 %@", requestIdentifier);
            //你自己的需求例如下面：
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"本地通知" message:@"成功添加推送" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancelAction];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            //此处省略一万行需求。。。。
        }
    }];
    
}
#pragma mark - iOS10 收到通知（本地和远端） UNUserNotificationCenterDelegate
//App处于前台接收通知时
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    
    //收到推送的请求
    UNNotificationRequest *request = notification.request;
    
    //收到推送的内容
    UNNotificationContent *content = request.content;
    
    //收到用户的基本信息
    NSDictionary *userInfo = content.userInfo;
    
    //收到推送消息的角标
    NSNumber *badge = content.badge;
    
    //收到推送消息body
    NSString *body = content.body;
    
    //推送消息的声音
    UNNotificationSound *sound = content.sound;
    
    // 推送消息的副标题
    NSString *subtitle = content.subtitle;
    
    // 推送消息的标题
    NSString *title = content.title;
    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSLog(@"iOS10 收到远程通知:%@",userInfo);
    }else {
        // 判断为本地通知
        NSLog(@"iOS10 收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
    // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    completionHandler(UNNotificationPresentationOptionBadge|
                      UNNotificationPresentationOptionSound|
                      UNNotificationPresentationOptionAlert);
    
}


//App通知的点击事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler{
    //收到推送的请求
    UNNotificationRequest *request = response.notification.request;
    
    //收到推送的内容
    UNNotificationContent *content = request.content;
    
    //收到用户的基本信息
    NSDictionary *userInfo = content.userInfo;
    
    //收到推送消息的角标
    NSNumber *badge = content.badge;
    
    //收到推送消息body
    NSString *body = content.body;
    
    //推送消息的声音
    UNNotificationSound *sound = content.sound;
    
    // 推送消息的副标题
    NSString *subtitle = content.subtitle;
    
    // 推送消息的标题
    NSString *title = content.title;
    
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSLog(@"iOS10 收到远程通知:%@",userInfo);
    }else {
        // 判断为本地通知
        NSLog(@"iOS10 收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
    completionHandler(); // 系统要求执行这个方法
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"UserNotifications"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
