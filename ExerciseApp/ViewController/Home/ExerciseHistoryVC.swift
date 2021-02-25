//
//  ExerciseHistoryVC.swift
//  ExerciseApp
//
//  Created by developer on 2/25/21.
//

import UIKit
import CRRefresh
import LoadingPlaceholderView

class ExerciseHistoryVC: UIViewController {

    @IBOutlet weak var historyTableView: UITableView!{
        didSet {
            historyTableView.coverableCellsIdentifiers = coverableCellsIds
        }
    }
    var pageNum = 1
    var workouts = [WorkoutModel]()
    var rowCount = 0
    let coverableCellsIds = ["PlaceholderCell", "PlaceholderCell", "PlaceholderCell", "PlaceholderCell"]
    private var loadingPlaceholderView = LoadingPlaceholderView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadingPlaceholderView.cover(view)
        self.getWorkouts()
    }
    
    func setupTableView(){
        
        let nibName = UINib(nibName: "HeaderCell", bundle: nil)
        self.historyTableView.register(nibName, forHeaderFooterViewReuseIdentifier: "HeaderCell")
        
        loadingPlaceholderView.gradientColor = .white
        loadingPlaceholderView.backgroundColor = .white
        
        let animator = RamotionAnimator(ballColor: UIColor(red: 0.027, green: 0.408, blue: 0.624, alpha: 0.4), waveColor: .white)
        animator.backgroundColor = .clear
        historyTableView.cr.addHeadRefresh(animator: NormalHeaderAnimator()) { [weak self] in
            self?.pageNum = 1
            self?.getWorkouts()
        }

        
        historyTableView.cr.addFootRefresh(animator: NormalFooterAnimator()) { [weak self] in
            
            if (self?.workouts.count)! < self!.rowCount {
                self?.getWorkouts()
            }else{
                self!.historyTableView.cr.noticeNoMoreData()
            }
             
        }
    }

    func getWorkouts(){
        self.showHUD()
        let params = [
            "order_by": ""] as [String : Any]
        ApiService.getWorkouts(page: pageNum, params: params) { (success, data) in
            self.dismissHUD()
            if success {
                if self.pageNum == 1 {
                    self.workouts.removeAll()
                }
                
                if let next = data!["next"] as? String, !next.isEmpty {
                    self.pageNum += 1
                }
                
                if let count = data!["count"] as? Int {
                    self.rowCount = count
                }
                
                if let results = data!["results"] as? [[String:Any]] {
                   
                    if results.count == 0 {
                        self.historyTableView.cr.noticeNoMoreData()
                    }else{
                        self.historyTableView.cr.resetNoMore()
                    }
                    
                    for item in results {
                        self.workouts.append(WorkoutModel(item))
                    }
                    self.historyTableView.reloadData()
                    self.historyTableView.cr.endHeaderRefresh()
                    self.historyTableView.cr.endLoadingMore()
                }else{
                    self.historyTableView.cr.endHeaderRefresh()
                    self.historyTableView.cr.endLoadingMore()
                    self.historyTableView.cr.noticeNoMoreData()
                }
            }else{
                self.pageNum = 1
                self.workouts.removeAll()
                self.historyTableView.cr.endHeaderRefresh()
                self.historyTableView.cr.endLoadingMore()
                self.historyTableView.cr.noticeNoMoreData()
                
                self.showFailureAlert()
            }
            
            self.loadingPlaceholderView.uncover()
        }
    }
}

extension ExerciseHistoryVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderCell" ) as! HeaderCell
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from:self.workouts[section].datetime)!
        
        dateFormatter.dateFormat = "EEEE LLL dd, yyyy"
        let month = dateFormatter.string(from: date)
        
        headerView.lblMonth.text = month
        return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.workouts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryContainerTVCell", for: indexPath) as! HistoryContainerTVCell
        cell.workout = self.workouts[indexPath.section]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var count = 0
        
        self.workouts[indexPath.section].exercises.forEach { (exercise) in
            
            exercise.sets.forEach { (set) in
                count += 1
            }
        }
        
        if count == 0 {
            return 0
        }
        
        return CGFloat(32 * count + 36)
    }
    
}
