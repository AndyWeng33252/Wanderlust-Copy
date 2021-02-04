//
//  TabBarViewController.swift
//  WanderlustApp
//
//  Created by Mallory Butt on 11/12/20.
//

import UIKit
import FirebaseAuth

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        /// listen for requests
        db!.collection("users").document((Auth.auth().currentUser?.uid)!).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
            fetchUser(uid: document.documentID) { user in
                currentUser = user
                if((currentUser?.requests.count)! > 0) {
                    self.tabBar.items?[3].badgeValue = String((currentUser?.requests.count)!)
                } else {
                    self.tabBar.items?[3].badgeValue = nil
                }
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let index = tabBarController.selectedIndex
        print(index)
        if index == 1 {
            if let navigVC = viewController as? UINavigationController,
               let vc = navigVC.viewControllers[0] as? ExploreViewController {
                if vc.isViewLoaded && (vc.view.window != nil) {
                    let visibleIndex = vc.collectionView.indexPathsForVisibleItems
                    if visibleIndex.count != 0 {
                        vc.collectionView.scrollToItem(at: IndexPath (item: 0, section: 0), at: .top, animated: true)
                    }
                }
            }
        }
    }
}
    


