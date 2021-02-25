//
//  AddRepsVC.swift
//  ExerciseApp
//
//  Created by developer on 2/24/21.
//

import UIKit
import TTGTagCollectionView
import CRNotifications

public func delay(_ delay: Double, closure: @escaping () -> Void) {
    let deadline = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(
        deadline: deadline,
        execute: closure
    )
}

class AddRepsVC: UIViewController {

    @IBOutlet weak var exerciseTagView: TTGTextTagCollectionView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var unitDropDown: DropDown!
    @IBOutlet weak var weightField: UITextField!{
        didSet{
            weightField.layer.borderWidth = 1
            weightField.layer.borderColor = SUB_COLOR?.cgColor
            weightField.layer.cornerRadius = 3
            weightField.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var repsField: UITextField!{
        didSet{
            repsField.layer.borderWidth = 1
            repsField.layer.borderColor = SUB_COLOR?.cgColor
            repsField.layer.cornerRadius = 3
            repsField.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var lblExercise: UILabel!
    
    private lazy var paginationManager: HorizontalPaginationManager = {
        let manager = HorizontalPaginationManager(scrollView: self.collectionView)
        manager.delegate = self
        return manager
    }()
    
    private var isDragging: Bool {
        return self.collectionView.isDragging
    }
    var categories: [String] = ["Push","Pull","Legs","Core"]
    var height: CGFloat = 0
    var selectedCategory = ""{
        didSet{
            if selectedCategory.isEmpty {
                self.lblExercise.text = "Exercises"
            }else{
                self.lblExercise.text = selectedCategory
            }
        }
    }
    var query = ""
    var pageNum = 1
    var itemCount = 0
    var exercises = [Exercise]()
    var filteredExercises = [Exercise]()
    var selectedExercise: Exercise?
    var units = ["kg","lb"]
    var selectedUnit = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initTagView()
        initUnitDropDown()
        setupPagination()
        fetchItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        height = CGFloat((self.view.frame.size.width - 24) / 3)
        heightConstraint.constant = height + 60
    }
    
    func initTagView(){
        
        let configure = TTGTextTagConfig()
        configure.textFont = UIFont(name: "Mulish-Medium.ttf", size: 14)
        configure.textColor = UIColor(red: 0.17, green: 0.17, blue: 0.22, alpha: 0.7)
        configure.selectedTextColor = .white
        configure.selectedBackgroundColor = COLOR2
        configure.borderColor = .clear
        configure.cornerRadius = 4
        configure.backgroundColor = UIColor(red: 239.0/255, green: 240.0/255, blue: 239.0/255, alpha: 0.5)
        configure.borderWidth = 0
        configure.extraSpace = CGSize(width: 32, height: 15)
        configure.exactHeight = 32
        configure.shadowColor = .clear
        exerciseTagView.defaultConfig = configure
        exerciseTagView.scrollDirection = .vertical
        exerciseTagView.enableTagSelection = true
        exerciseTagView.showsHorizontalScrollIndicator = false
        exerciseTagView.horizontalSpacing = 14
        exerciseTagView.alignment = .center
        exerciseTagView.delegate = self
        exerciseTagView.addTags(categories)
        
    }
    
    func initUnitDropDown(){
        unitDropDown.optionArray = units
        unitDropDown.selectedIndex = 0
        unitDropDown.isSearchEnable = false
        unitDropDown.selectedRowColor = .clear
        unitDropDown.text = units[UserInfo.shared.unit]
       
        unitDropDown.didSelect { (unit, index, id) in
            UserInfo.shared.setUserInfo(.unit, value: index)
            self.selectedUnit = index
        }
    }

    func getAllExercises(completion: @escaping (Bool?) -> Void){
        
        let params = [
            "order_by": "name",
            "active": true,
            "category": selectedCategory,
            "q": query] as [String : Any]
        ApiService.getAllExercises(page: pageNum, params: params) { [self] (success, data) in
//            self.dismissHUD()
            completion(true)
            if success {
                if self.pageNum == 1 {
//                    self.seletedCount = 0
                    self.exercises.removeAll()
                    self.filteredExercises.removeAll()
                }
                
                if let next = data!["next"] as? String, !next.isEmpty {
                    self.pageNum += 1
                }
                
                if let count = data!["count"] as? Int {
                    self.itemCount = count
                }
                
                if let results = data!["results"] as? [[String:Any]] {

                    
                    for item in results {
                        self.exercises.append(Exercise(item))
                        self.filteredExercises.append(Exercise(item))
                    }
                    
                    self.collectionView.reloadData()
                    
                }
            }else{
                self.pageNum = 1
                self.exercises.removeAll()
                self.filteredExercises.removeAll()
                self.showFailureAlert()
            }
        }
    }
    
    private func createWorkout(){

        self.showHUD()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateTime = dateFormatter.string(from: Date())

        var titles = [String]()
        var ids = [String]()
        if !selectedExercise!.category.isEmpty {
            titles.append(selectedExercise!.category)
        }
        ids.append(selectedExercise!.id)

        var title = ""
        if titles.count > 0 {
            title = titles.joined(separator: "/")
        }

        let params = [
            "datetime": dateTime,
            "title": title,
            "body_weight": weightField.text!.isEmpty ? 0 : Int(weightField.text!) as Any,
            "energy_level": 0,
            "comments": "",
            "exercises":ids] as [String : Any]

        ApiService.createWorkout(params: params) { [self] (success, data) in
            if success {

                if let id = data!["id"] as? String {
                    addReps(id,isNew: true)
                }

//                if let id = data!["id"] as? String {
//                    let vc = self.storyboard?.instantiateViewController(identifier: "WorkoutDetailVC") as! WorkoutDetailVC
//                    vc.workoutID = id
//                    vc.isFromCreate = true
//                    self.navigationController?.pushViewController(vc, animated: true)
//                }
            }else{
                self.dismissHUD()
                self.showFailureAlert()
            }
        }
    }
    
    private func addReps(_ workoutId: String, isNew: Bool){
        let params = [
            "num": weightField.text!.isEmpty ? 0 : Int(weightField.text!) as Any,
            "reps": repsField.text!.isEmpty ? 0 : Int(repsField.text!) as Any,
            "workout": workoutId,
            "exercise": selectedExercise!.id] as [String : Any]
        ApiService.workoutSets(workoutId: workoutId, params: params) { (success, data) in
            self.dismissHUD()
            
            if success {
                
                for item in self.filteredExercises {
                    item.isSelected = false
                }
                self.selectedExercise = nil
                self.collectionView.reloadData()

                let nc = NotificationCenter.default
                
                if isNew {
                    nc.post(name: Notification.Name("WorkoutCreated"), object: nil)
                    CRNotifications.showNotification(textColor: MAIN_COLOR!, backgroundColor: BACKGROUND_COLOR!, image: UIImage(named: "success"), title: "Success!", message: "You successfully created Workout.", dismissDelay: 2.0)
                }else{
                    nc.post(name: Notification.Name("addToWorkoutNotification"), object: nil)
                    nc.post(name: Notification.Name("workoutUpdated"), object: nil)
                }
                
                let vc = self.storyboard?.instantiateViewController(identifier: "ExerciseHistoryVC") as! ExerciseHistoryVC
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    private func updateWorkout(_ workout: WorkoutModel){
        
        self.showHUD()
        
        var ids = [String]()
        for item in workout.exercises {
            ids.append(item.id)
        }
        ids.append(selectedExercise!.id)

        var orders = ""
        if !workout.order.isEmpty {
            orders = ids.joined(separator: ",")
            workout.order.append(contentsOf: ",\(orders)")
        }
        
        let params = [
            "datetime": workout.datetime,
            "title": workout.title,
            "body_weight": weightField.text!.isEmpty ? 0 : Int(weightField.text!) as Any,
            "energy_level": workout.energy_level,
            "comments": workout.comments,
            "order": orders,
            "exercises":ids] as [String : Any]
        
        ApiService.updateWorkout(id: workout.id,params: params) { [self] (success, data) in
            self.dismissHUD()
            if success {
                
                if let id = data!["id"] as? String {
                    addReps(id, isNew: false)
                }
                
//                for item in self.filteredExercises {
//                    item.isSelected = false
//                }
//                self.seletedCount = 0
//                self.checkedExercises.removeAll()
//                self.collectionView.reloadData()
//
//                let nc = NotificationCenter.default
//                nc.post(name: Notification.Name("addToWorkoutNotification"), object: nil)
//                nc.post(name: Notification.Name("workoutUpdated"), object: nil)
//                self.back()
            }else{
                self.showFailureAlert()
            }
        }
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        
        if self.selectedExercise == nil {
            let alert = UIAlertController(title: "Warning", message: "Please select exercise.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { (action) in
                
            }))
            self.present(alert, animated: true)
            return
        }
        self.showHUD()
        let params = [
            "order_by": ""] as [String : Any]
        ApiService.hasTodayWorkout(params: params) { (hasWorkout, workout) in
            if !hasWorkout {
                self.createWorkout()
            }else{
                self.updateWorkout(workout!)
            }
        }
    }
}

extension AddRepsVC: TTGTextTagCollectionViewDelegate {
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool, tagConfig config: TTGTextTagConfig!) {
        
        for i in 0...self.exerciseTagView.allTags()!.count - 1 {
            
            if i != index {
                self.exerciseTagView.setTagAt(UInt(i), selected: false)
            }
            
        }
        
        if selected {
            self.selectedCategory = tagText
            self.pageNum = 1
            getAllExercises(completion: {_ in })
        }else{
            self.selectedCategory = ""
            self.pageNum = 1
            getAllExercises(completion: {_ in })
        }
    }
}

extension AddRepsVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredExercises.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseCVCell", for: indexPath) as! ExerciseCVCell
        
        if selectedExercise == nil {
            self.filteredExercises[indexPath.item].isSelected = false
        }else{
            if filteredExercises[indexPath.item].id == selectedExercise!.id {
                self.filteredExercises[indexPath.item].isSelected = true
            }else{
                self.filteredExercises[indexPath.item].isSelected = false
            }
        }
        cell.initCell(self.filteredExercises[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: height, height: height + 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        if filteredExercises[indexPath.item].isSelected {
            self.selectedExercise = nil
            filteredExercises[indexPath.item].isSelected = false
        }else{
            self.filteredExercises.forEach { (exercise) in
                exercise.isSelected = false
            }
            self.filteredExercises[indexPath.item].isSelected = true
            self.selectedExercise = self.filteredExercises[indexPath.item]
        }
        
        self.collectionView.reloadData()
     
    }
}

extension AddRepsVC: HorizontalPaginationManagerDelegate {
    
    private func setupPagination() {
        self.paginationManager.refreshViewColor = .white
        self.paginationManager.loaderColor = MAIN_COLOR!
    }
    
    private func fetchItems() {
        self.paginationManager.initialLoad()
    }
    
    func refreshAll(completion: @escaping (Bool) -> Void) {
        self.pageNum = 1
        self.getAllExercises(completion: {_ in
            completion(true)
        })
    }
    
    func loadMore(completion: @escaping (Bool) -> Void) {
        if self.exercises.count < self.itemCount {
            self.getAllExercises(completion: {_ in
                completion(true)
            })
        }else{
            completion(true)
        }
    }
    
}
