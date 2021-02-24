//
//  AddRepsVC.swift
//  ExerciseApp
//
//  Created by developer on 2/24/21.
//

import UIKit
import TTGTagCollectionView

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
    var selectedExercises = [Exercise]()
    var units = ["kg","lb"]
    var selectedUnit = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initTagView()
        initUnitDropDown()
        setupPagination()
        fetchItems()
        getAllExercises(completion: {_ in })
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
            "order_by": "-created",
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
                   
//                    if results.count == 0 {
//                        self.collectionView.cr.noticeNoMoreData()
//                    }else{
//                        self.collectionView.cr.resetNoMore()
//                    }
                    
                    for item in results {
                        self.exercises.append(Exercise(item))
                        self.filteredExercises.append(Exercise(item))
                    }
                    
                    self.collectionView.reloadData()
//                    self.collectionView.cr.endHeaderRefresh()
//                    self.collectionView.cr.endLoadingMore()
                    
                }else{
//                    self.collectionView.cr.endHeaderRefresh()
//                    self.collectionView.cr.endLoadingMore()
//                    self.collectionView.cr.noticeNoMoreData()
                }
            }else{
                self.pageNum = 1
                self.exercises.removeAll()
                self.filteredExercises.removeAll()
                self.showFailureAlert()
//                self.collectionView.cr.endHeaderRefresh()
//                self.collectionView.cr.endLoadingMore()
//                self.collectionView.cr.noticeNoMoreData()
            }
        }
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapSave(_ sender: Any) {
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
        cell.initCell(self.filteredExercises[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: height, height: height + 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.filteredExercises.forEach { (exercise) in
            exercise.isSelected = false
        }
        
        self.filteredExercises[indexPath.item].isSelected = true
        
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
