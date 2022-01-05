//
//  CareFeedViewController.swift
//  Medicine Reminder
//
//  Created by Sofie Tjønneland Urhaug on 22/12/2021.
//
import Foundation
import CareKitUI
import CareKit
import CareKitStore
import os.log
import SwiftUI
import HealthKitUI
import ResearchKit
import UIKit

final class CareFeedViewController : OCKDailyPageViewController, OCKSurveyTaskViewControllerDelegate {
    
    let userData: UserData
    
    init (userData: UserData, storeManager: OCKSynchronizedStoreManager) {
        self.userData = userData
        super.init(storeManager: storeManager)
    }

    override func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController, prepare listViewController: OCKListViewController, for date: Date) {


        checkIfOnboardingIsComplete { isOnboarded in
            
            guard isOnboarded else {
                let onboardCard = OCKSurveyTaskViewController(
                                   taskID: "onboarding",
                                   eventQuery: OCKEventQuery(for: date),
                                   storeManager: self.storeManager,
                                   survey: Surveys.onboardingSurvey(),
                                   extractOutcome: { _ in [OCKOutcomeValue(Date())] }
                )
                onboardCard.surveyDelegate = self

                listViewController.appendViewController(onboardCard, animated: false)

                return
            }
            
            self.getOnboardingResults()
            
            let identifiers = ["betablocker"]
            var query = OCKTaskQuery(for: date)
            query.ids = identifiers
            query.excludesTasksWithNoEvents = true

            self.storeManager.store.fetchAnyTasks(query: query, callbackQueue: .main) { result in
                        
                        switch result {
                        
                        case .failure(let error): print("Error in fetchanytasks: \(error)")
                        case .success(let tasks):
                            if let betablockerTask = tasks.first(where: { $0.id == "betablocker"}) {
                                print("Adding betablocker task")
                                //let betablockerCard = OCKSimpleTaskViewController(
                                let betablockerCard = OCKSimpleTaskViewController(task: betablockerTask, eventQuery: .init(for: date), storeManager: self.storeManager)
                                listViewController.appendViewController(betablockerCard, animated: false)
                            }
                            
                            //MARK: Add other views than tasks here:
                            /*let hrTitle = "Resting heartrate"
                            let restHRview = HRView()
                            restHRview.headerView.titleLabel.text = hrTitle
                            restHRview.healthValueView.titleLabel.text = self.userData.isHRCurrent() ? "\(self.userData.restingHeartRates[self.userData.restingHeartRates.count - 1])" : "-.-"

                            listViewController.appendView(restHRview, animated: false)
                            
                            let averageHRTitle = "Average HR"
                            let averageHRView = HRView()
                            averageHRView.headerView.titleLabel.text = averageHRTitle
                            averageHRView.healthValueView.titleLabel.text = "\(Double(self.userData.restingHeartRates.average))"
                            
                            listViewController.appendView(averageHRView, animated: false)*/
                            
                        }
                    }
        }
    }
            
           
         
    
    private func checkIfOnboardingIsComplete(_ completion: @escaping (Bool) -> Void) {

            var query = OCKOutcomeQuery()
            query.taskIDs = ["onboarding"]

            storeManager.store.fetchAnyOutcomes(
                query: query,
                callbackQueue: .main) { result in

                switch result {

                case .failure:
                    print("Failed to fetch onboarding outcomes!")
                    completion(false)

                case let .success(outcomes):
                    completion(!outcomes.isEmpty)
            }
        }
    }
    
    private func getOnboardingResults () {
        var query = OCKOutcomeQuery()
        query.taskIDs = ["onboarding"]
        
        storeManager.store.fetchAnyOutcomes(
            query: query,
            callbackQueue: .main) { result in
            print("getting onboarding results")
    
                
        }
        
        
    }
    
    // MARK: SurveyTaskViewControllerDelegate
      func surveyTask(
          viewController: OCKSurveyTaskViewController,
          for task: OCKAnyTask,
          didFinish result: Result<ORKTaskViewControllerFinishReason, Error>) {

          if case let .success(reason) = result, reason == .completed {
              reload()
          }
      }

      func surveyTask(
          viewController: OCKSurveyTaskViewController,
          shouldAllowDeletingOutcomeForEvent event: OCKAnyEvent) -> Bool {

          event.scheduleEvent.start >= Calendar.current.startOfDay(for: Date())
      }
    
}

//final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {
//
//    override func updateView(
//        _ view: OCKInstructionsTaskView,
//        context: OCKSynchronizationContext<OCKTaskEvents>) {
//
//        super.updateView(view, context: context)
//
//        if let event = context.viewModel.first?.first, event.outcome != nil {
//            view.instructionsLabel.isHidden = false
//
////            let pain = event.answer(kind: Surveys.checkInPainItemIdentifier)
////            let sleep = event.answer(kind: Surveys.checkInSleepItemIdentifier)
//            //
//
//            view.instructionsLabel.text = """
//                Pain: \(Int(pain))
//                """
//        } else {
//            view.instructionsLabel.isHidden = true
//        }
//    }
//}

private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}
