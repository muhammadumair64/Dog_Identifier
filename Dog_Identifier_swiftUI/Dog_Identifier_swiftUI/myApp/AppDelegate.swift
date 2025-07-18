//
import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import SwiftUI
import CocoaLumberjack
import GoogleMobileAds
import SDWebImage
import SDWebImageWebPCoder

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
//        DDLog.add(DDOSLogger.sharedInstance)
//        DDLog.add(DDFileLogger())
//
        initializeLogging()
//        let WebPCoder = SDImageWebPCoder.shared
//        SDImageCodersManager.shared.addCoder(WebPCoder)
        
        WebPImageSetup.configure()
        
        FirebaseApp.configure()
        MobileAds.shared.start(completionHandler: nil)
         InAPPManager.shared.fetchProducts()
     //   Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })

        application.registerForRemoteNotifications()

        Messaging.messaging().token { token, error in
            if let error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token {
                print("FCM registration token: \(token)")
            }
        }

        return true
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Oh no! Failed to register for remote notifications with error \(error)")
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var readableToken = ""
        for index in 0 ..< deviceToken.count {
            readableToken += String(format: "%02.2hhx", deviceToken[index] as CVarArg)
        }
        print("Received an APNs device token: \(readableToken)")
    }
}

func initializeLogging() {
    let coloredFormatter = ColoredLogFormatter()
    
    // Configure the logger
    let osLogger = DDOSLogger.sharedInstance
    osLogger.logFormatter = coloredFormatter
    DDLog.add(osLogger)

    // Log initialization message
    DDLogInfo("CocoaLumberjack logging initialized.")
}



//extension AppDelegate: MessagingDelegate {
//    @objc func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("Firebase token: \(String(describing: fcmToken))")
//    }
//}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([[.banner, .list, .sound]])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: Notification.Name("didReceiveRemoteNotification"),
            object: nil,
            userInfo: userInfo
        )
        completionHandler()
    }
}

