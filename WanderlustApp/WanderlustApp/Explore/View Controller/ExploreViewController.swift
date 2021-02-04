//
//  ExploreViewController.swift
//  WanderlustApp
//
//  Created by Bryan Yang on 10/15/20.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import MapKit
import FirebaseUI


private let cellIdentifier = "ExploreCell"

class ExploreViewController: UIViewController, UICollectionViewDelegate, UISearchBarDelegate, UITableViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTableView: UITableView!
    
    /// Logged in user
    var user:FirebaseAuth.User?
    
    /// List of entries for this trip
    var entries:[Entry] = []
    
    /// Search completer
    lazy var searchCompleter: MKLocalSearchCompleter = {
        let sC = MKLocalSearchCompleter()
        sC.delegate = self
        return sC
    }()
    
    /// Refresher to refresh entries on drag down
    var refresher: UIRefreshControl!
    
    /// List of search results
    var searchResults:[MKLocalSearchCompletion] = []
    
    /// Search query for filtering
    var searchQuery:String = ""
    
    /// Cache for entry images
    let cache = NSCache<NSString, UIImage>()
    
    /// True if page is filtered, false if not
    var isFiltered:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchCompleter.delegate = self
        searchTableView.delegate = self
        searchTableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refreshEntries), for: .valueChanged)
        collectionView.addSubview(refresher)
        refreshEntries()
    }
    
    @objc func refreshEntries() {
        DispatchQueue.global(qos: .background).async {
            self.loadEntryData()
        }
    }
    
    // Hide keyboard when user drags
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }
    
    // Hide keyboard on search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        exitSearch(loadEntries: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        clearAutocomplete()
        if !isFiltered {
            transitionSearchView(search: true)
            searchBar.showsCancelButton = true
        }
        else {
            searchBar.showsCancelButton = false
            searchBar.endEditing(true)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        exitSearch(loadEntries: false)
    }
    
    /// Exit searching and transition back to collection view
    /// - Parameters:
    ///   - loadEntries: True if entries should be reloaded, false if not
    ///   - transition: Optional boolean to indicate whether transition to collection view should happen, default is true
    func exitSearch(loadEntries: Bool, transition: Bool? = nil) {
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        clearAutocomplete()
        if loadEntries {
            refreshEntries()
        }
        if let transition = transition {
            if transition {
                transitionSearchView(search: false)
            }
        }
        else {
            transitionSearchView(search: false)
        }
    }
    
    // This method declares that whenever the text in the searchbar is change to also update
    // the query that the searchCompleter will search based off of
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
        searchQuery = searchText
        if searchText.isEmpty && isFiltered {
            exitSearch(loadEntries: true, transition: false)
            searchBar.showsCancelButton = false
        }
    }
    
    /// Animate transition between search view and collection view
    /// - Parameter search: True to transiton to search, false to transition to collection view
    func transitionSearchView(search: Bool) {
        UIView.animate(withDuration: 1, animations: {
            self.collectionView.alpha = search ? 0 : 1
        })
        UIView.animate(withDuration:  1, animations: {
            self.searchTableView.alpha = search ? 1 : 0
        })
    }
    
    /// Clear autocomplete results
    func clearAutocomplete() {
        searchResults.removeAll()
        searchTableView.reloadData()
    }
    
    /// Load entry data from firebase
    @objc func loadEntryData() {
        print("Begin getting entries")
        print("Search query: \(searchQuery)")
        user = Auth.auth().currentUser
        if let _ = user {
            let ref = self.searchQuery.isEmpty ? db?.collection("entries").order(by: "timestamp", descending: true) : db?.collection("entries").whereField("locationName", isEqualTo: self.searchQuery).order(by: "timestamp", descending: true)
            ref?.getDocuments(completion: { (snapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                }
                else {
                    self.entries.removeAll()
                    for document in snapshot!.documents {
                        let result = Result {
                          try document.data(as: Entry.self)
                        }
                        switch result {
                        case .success(let entry):
                            if let entry = entry,
                               // TODO: Remove this check later once we have legit data
                               let _ = entry.coverPhoto {
                                self.entries.append(entry)
                                print("Added \(entry)")
                            }
                            else {
                                print("Document does not exist")
                            }
                        case .failure(let error):
                            print("Error decoding entry: \(error)")
                        }
                    }
                    self.isFiltered = self.searchQuery.isEmpty ? false : true
                    self.searchQuery = ""
                    DispatchQueue.main.async {
                        self.refresher.endRefreshing()
                        self.collectionView.reloadData()
                    }
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EntryInfoSegue" {
            let otherVC = segue.destination as? EntryInfoViewController
            let cell = sender as! UICollectionViewCell
            let indexPath = collectionView.indexPath(for: cell)
            let entry = entries[indexPath!.row]
            otherVC?.entryID = entry.entryId
        }
    }
}

extension ExploreViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return entries.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ExploreCollectionViewCell
        let row = indexPath.row
        let entry = entries[row]
    
        // Load image from firebase
        if let coverPhotoUrl = entry.coverPhoto, coverPhotoUrl.starts(with: "https://") {
            if let imageFromCache = cache.object(forKey: coverPhotoUrl as NSString) {
                cell.imageView.image = imageFromCache
            }
            else {
                let ref = storage?.reference(forURL: coverPhotoUrl)
                ref?.getData(maxSize: 500000, completion: { (data, error) in
                    if let error = error {
                        print("Error downloading image: \(error.localizedDescription)")
                        let image = UIImage(named: "entryPlaceholder.png")
                        cell.imageView.image = image
                    }
                    else {
                        let image = UIImage(data: data!)
                        self.cache.setObject(image!, forKey: coverPhotoUrl as NSString)
                        cell.imageView.image = image
                    }
                })
            }
        }
        return cell
    }
}

extension ExploreViewController : UICollectionViewDelegateFlowLayout {
    
    // Calculate appropriate size for each tile
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {

    let paddingSpace = Grid.GRID_SECTION_INSETS.left * (Grid.ITEMS_PER_ROW + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / Grid.ITEMS_PER_ROW

    return CGSize(width: widthPerItem, height: widthPerItem)

    }
    
    // Remove space between tiles in a row
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Grid.GRID_SECTION_INSETS.left
    }

    // Remove space between rows
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}

extension ExploreViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreSearchCell", for: indexPath as IndexPath)
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        searchBar.text = cell?.textLabel?.text
        
        let searchCompletion = searchResults[indexPath.row]
        MKLocalSearch(request: MKLocalSearch.Request(completion: searchCompletion)).start(completionHandler: {
            (response, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let response = response {
                guard let item = response.mapItems.first else {return}
                self.searchQuery = item.placemark.title!
                print("Cell tapped: \(self.searchQuery)")
                self.exitSearch(loadEntries: true)
                
            }
        })
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ExploreViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results.filter { $0.subtitle != "Search Nearby" }
        self.searchTableView.reloadData()
        
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search failed: \(error.localizedDescription)")
    }
}
