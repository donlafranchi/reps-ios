//
//  ExerciseCVCell.swift
//  ExerciseApp
//
//  Created by developer on 2/24/21.
//

import UIKit

class ExerciseCVCell: UICollectionViewCell {
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblMuscle: UILabel!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var imgCheck: UIImageView!
    
    var exercise = Exercise()

    func initCell(_ exercise: Exercise){
        
        self.exercise = exercise
        self.lblName.text = self.exercise.name
        self.lblMuscle.text = self.exercise.category
        self.overlayView.isHidden = !self.exercise.isSelected
        self.imgCheck.isHidden = !self.exercise.isSelected
        
        if self.exercise.isSelected {
            self.lblName.textColor = .white
            self.lblMuscle.textColor = .white
        }else{
            self.lblName.textColor = MAIN_COLOR
            self.lblMuscle.textColor = SUB_COLOR
        }
    }
}
