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
import CareKitStore


final class InsightsViewController: OCKListViewController {
    
    let storeManager: OCKSynchronizedStoreManager
    let userData: UserData
    
    init(userData: UserData, storeManager: OCKSynchronizedStoreManager) {
        self.storeManager = storeManager
        self.userData = userData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let streakView = StreakView()
        streakView.headerView.titleLabel.text = "Streak is "
        
        //Spacer view
        appendView(streakView, animated: false)
        
        let betablockerSeries = OCKDataSeriesConfiguration(taskID: "betablocker", legendTitle: "Betablocker", gradientStartColor: view.tintColor, gradientEndColor: view.tintColor, markerSize: 3, eventAggregator: .countOutcomes)
       
        let betablockerInsight = OCKCartesianChartViewController(plotType: .scatter, selectedDate: Date(), configurations: [betablockerSeries], storeManager: storeManager)
        
        self.getBetablockerResults()
        
        appendViewController(betablockerInsight, animated: false)
        
        //Spacer view
        appendView(UIView(), animated: false)
        
    }
    
    private func getBetablockerResults () {
        var query = OCKOutcomeQuery()
        query.taskIDs = ["betablocker"]
        
        storeManager.store.fetchAnyOutcomes(
            query: query,
            callbackQueue: .main) { result in
                switch result {
                case .failure:
                    NSLog("Failed to fetch betablocker outcomes")
                case let .success(outcomes):
                    NSLog("Betablocker outcomes:")
                    NSLog("\(outcomes)")
                    NSLog("Number of outcomes: \(outcomes.count)")
                 
                }
            }
    }
}
