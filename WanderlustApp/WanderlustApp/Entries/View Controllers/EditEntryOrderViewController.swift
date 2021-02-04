//
//  EditEntryOrderViewController.swift
//  WanderlustApp
//
//  Created by Hudson  Tran on 10/18/20.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

// View Controller to edit Entry Order
class EditEntryOrderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var entryList = [CustomAnnotation]()
    let entryCellIdentifier = "entryCell"
    var delegate:EditTripViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isEditing = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dragInteractionEnabled = true
        
    }
    
    // Sets the entryList to the new entry order
    override func viewWillDisappear(_ animated: Bool) {
        let tripEditVC = delegate as EditTripViewController
        tripEditVC.entryList = entryList
    }
}

// Extension to handle the Table View
extension EditEntryOrderViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entryList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: entryCellIdentifier, for: indexPath as IndexPath)
        let row = indexPath.row
        cell.textLabel?.text = entryList[row].title
        return cell
    }

    //Allows movement of all the rows
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Gets rid of the subtract sign on the left of the cell
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    // Function that handles the reordering of entries
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let moveTitle = entryList[sourceIndexPath.row]
        entryList.remove(at: sourceIndexPath.row)
        entryList.insert(moveTitle, at: destinationIndexPath.row)
    }
}
