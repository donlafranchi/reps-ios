//
//  HomeVC.swift
//  ExerciseApp
//
//  Created by developer on 2/24/21.
//

import UIKit

class HomeVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func didTapAddReps(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(identifier: "AddRepsVC") as! AddRepsVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapSettings(_ sender: Any) {
        self.performSegue(withIdentifier: "goSettings", sender: nil)
    }
}
