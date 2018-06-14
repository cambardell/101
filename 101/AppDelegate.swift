

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
   
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool {
            FirebaseApp.configure()
            Database.database().isPersistenceEnabled = true
            // Initialize the Google Mobile Ads SDK.
            GADMobileAds.configure(withApplicationID: "ca-app-pub-4804366180565835~3263780833")
         
            return true
    }
    
   
    
    
}
