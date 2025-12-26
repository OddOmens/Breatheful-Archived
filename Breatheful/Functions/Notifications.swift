import SwiftUI
import UserNotifications
import Foundation
import UIKit
import CoreData

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var userProfile = UserProfile()

    // Core Data stack setup
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Breatheful")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // Save context method
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
        saveContext()
        userProfile.applicationDidEnterBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        userProfile.applicationWillEnterForeground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App became active")
        userProfile.applicationWillEnterForeground()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active")
        userProfile.applicationDidEnterBackground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")
        saveContext()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error)")
            }
        }
        return true
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var userProfile: UserProfile?

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("Scene entered background")
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        userProfile?.applicationDidEnterBackground()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("Scene will enter foreground")
        userProfile?.applicationWillEnterForeground()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("Scene became active")
        userProfile?.applicationWillEnterForeground()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
        userProfile?.applicationDidEnterBackground()
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            fatalError("No view context available")
        }
        
        let userProfile = UserProfile()
        self.userProfile = userProfile

        let contentView = ContentView()
            .environment(\.managedObjectContext, context)
            .environmentObject(userProfile)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
