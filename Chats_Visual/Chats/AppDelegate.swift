import UIKit

var account = Account(user: User(phone: "4085960635"))
var manager_global = MPCManager()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow!
    var manager = manager_global

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        // Set my phone number
        manager.setMyPhoneNumber(account.user.phone)
        manager.browser.startBrowsingForPeers()
        manager.advertiser.startAdvertisingPeer()
        
        // Configure window
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.backgroundColor = UIColor.whiteColor()
        window.rootViewController = UINavigationController(rootViewController: ChatsViewController())
        window.makeKeyAndVisible()

        return true
    }
}
