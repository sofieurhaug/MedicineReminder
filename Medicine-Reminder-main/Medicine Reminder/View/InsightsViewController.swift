//
//  InsightsViewController.swift
//  Medicine Reminder
//
//  Created by Sofie Tjønneland Urhaug on 22/12/2021.
//
import Foundation
import CareKit
import CareKitUI
import SwiftUI
import UIKit


final class InsightsViewController: OCKListViewController {
    
    let storeManager: OCKSynchronizedStoreManager
    @EnvironmentObject var userData: UserData
    
    init(storeManager: OCKSynchronizedStoreManager) {
        self.storeManager = storeManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //Spacer view
        appendView(UIView(), animated: false)
        
    }
}
