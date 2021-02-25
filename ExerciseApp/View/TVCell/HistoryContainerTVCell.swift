//
//  HistoryContainerTVCell.swift
//  ExerciseApp
//
//  Created by developer on 2/25/21.
//

import UIKit

class HistoryContainerTVCell: UITableViewCell {

    @IBOutlet weak var tableView: UITableView!
    var histories = [HistoryModel]()
    var units = ["kg","lb"]

    var workout: WorkoutModel?{
        didSet{
            makeHistoryData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func makeHistoryData(){
        print("made")
        self.histories.removeAll()
        self.workout?.exercises.forEach({ (exercise) in
            exercise.sets.forEach { (set) in
                let history = HistoryModel()
                history.name = exercise.name
                history.bodyWeight = set.num
                history.reps = set.reps
                history.date = set.modified!
                self.histories.append(history)
            }
        })
        
        self.histories.sort { (model1, model2) -> Bool in
            model1.date < model2.date
        }
        self.tableView.reloadData()
    }

}

extension HistoryContainerTVCell: UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.histories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTVCell", for: indexPath) as! HistoryTVCell
        let history = self.histories[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        
        cell.lblHistory.text = "\(history.name) | \(history.bodyWeight) \(units[UserInfo.shared.unit]) | \(history.reps) | \(dateFormatter.string(from: history.date))"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32
    }
    
    
}
