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
                let onboardCard = SurveyViewController(taskID: "onboarding", eventQuery: OCKEventQuery(for: Date()), storeManager: self.storeManager)
                
                listViewController.appendViewController(onboardCard, animated: false)

                return
            }
            
            self.getOnboardingResults()
            
            // Only show the betablocker task on the current date
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                let streakView = StreakView()
                streakView.headerView.titleLabel.text = "Streak is 1 ❤️‍🔥"
                listViewController.appendView(streakView, animated: false)
                
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
                                
                                let betablockerSeries = OCKDataSeriesConfiguration(taskID: "betablocker", legendTitle: "Betablocker", gradientStartColor: self.view.tintColor, gradientEndColor: self.view.tintColor, markerSize: 3, eventAggregator: .countOutcomes)
                               
                                let betablockerInsight = OCKCartesianChartViewController(plotType: .scatter, selectedDate: Date(), configurations: [betablockerSeries], storeManager: self.storeManager)
                                
                                self.getBetablockerResults()
                                
                                listViewController.appendViewController(betablockerInsight, animated: false)
                                
                            }
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
                switch result {
                case .failure:
                    print("Failed to fetch onboarding outcomes!")
                case let .success(outcomes):
                    print(self.userData.getTriggerBoundary())
                }
        }
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


private extension View {
    func formattedHostingController() -> UIHostingController<Self> {
        let viewController = UIHostingController(rootView: self)
        viewController.view.backgroundColor = .clear
        return viewController
    }
}


// 1. Subclass a task view controller to customize the control flow and present a ResearchKit survey!
class SurveyViewController: OCKInstructionsTaskViewController, ORKTaskViewControllerDelegate {

    // 2. This method is called when the use taps the button!
    override func taskView(_ taskView: UIView & OCKTaskDisplayable, didCompleteEvent isComplete: Bool, at indexPath: IndexPath, sender: Any?) {

        // 2a. If the task was uncompleted, fall back on the super class's default behavior or deleting the outcome.
        if !isComplete {
            super.taskView(taskView, didCompleteEvent: isComplete, at: indexPath, sender: sender)
            return
        }

        // 2b. If the user attemped to mark the task complete, display a ResearchKit survey.
        let surveyTask = Surveys.onboardingSurvey()
        let surveyViewController = ORKTaskViewController(task: surveyTask, taskRun: nil)
        surveyViewController.delegate = self

        present(surveyViewController, animated: true, completion: nil)
    }

    // 3. This method will be called when the user completes the survey.
    // Extract the result and save it to CareKit's store!
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        taskViewController.dismiss(animated: true, completion: nil)
        guard reason == .completed else {
            taskView.completionButton.isSelected = false
            return
        }
        
        // 4a. Retrieve the result from the ResearchKit survey
        let boundaryHRsurvey = taskViewController.result.results!.first(where: { $0.identifier == "onboarding.boundaryHRStep" }) as! ORKStepResult
        let boundaryHRResult = boundaryHRsurvey.results!.first as! ORKNumericQuestionResult
        let boundaryAnswer = Int(truncating: boundaryHRResult.numericAnswer ?? 0)
        
        let medicationTimeSurvey = taskViewController.result.results!.first(where: { $0.identifier == "onboarding.medicationTimeStep" }) as! ORKStepResult
        let medicationTimeResult = medicationTimeSurvey.results!.first as! ORKTimeOfDayQuestionResult
        let medicationAnswer = "\(medicationTimeResult.dateComponentsAnswer?.hour ?? 0)-\(medicationTimeResult.dateComponentsAnswer?.minute ?? 0)"
        
        //Adding it as one answer
        let answer = "\(boundaryAnswer)+\(medicationAnswer)"
    
        // 4b. Save the result into CareKit's store
        controller.appendOutcomeValue(value: answer, at: IndexPath(item: 0, section: 0), completion: nil)
        let userData = (UIApplication.shared.delegate as! AppDelegate).userData
        userData.setTriggerBoundary(boundary: Double(boundaryAnswer))
        userData.setMedicationTime(time: medicationAnswer)
    }
}
