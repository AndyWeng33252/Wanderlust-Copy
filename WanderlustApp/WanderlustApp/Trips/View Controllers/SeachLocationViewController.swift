//
//  SeachLocationViewController.swift
//  WanderlustApp
//
//  Created by Andy Weng on 11/18/20.
//

import UIKit
import MapKit
class SeachLocationViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTableView: UITableView!
    var delegate:EditTripViewController!
    var searchedLocation:String!
    /// Search completer
    lazy var searchCompleter: MKLocalSearchCompleter = {
        let sC = MKLocalSearchCompleter()
        sC.delegate = self
        return sC
    }()
    
    var searchResults:[MKLocalSearchCompletion] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.placeholder = "Enter A Location"
        searchBar.showsCancelButton = true
        searchCompleter.delegate = self
        searchTableView.delegate = self
        searchTableView.dataSource = self
    }
    

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }
    
    // When Search Is initiated with search button on keyboard perform segue
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchedLocation = searchBar.text
        performSearch()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
    
    // This method declares that whenever the text in the searchbar is change to also update
    // the query that the searchCompleter will search based off of
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //Sets the query string for MKLocationCompleter
        searchCompleter.queryFragment = searchText
        if searchText == "" {
            searchResults.removeAll()
            searchTableView.reloadData()
        }
    }
    
    func performSearch() {
        self.delegate.tappedLocationString = self.searchedLocation
        delegate.performSegue(withIdentifier: "goEdit", sender: delegate)
        self.dismiss(animated: true)
    }

}

extension SeachLocationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    ///Populate the table view with the results from the search reseults returned by MKLocalSearch
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreSearchCell", for: indexPath as IndexPath)
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    ///Once user selects a cell, then perform the search procedure
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let searchCompletion = searchResults[indexPath.row]
        MKLocalSearch(request: MKLocalSearch.Request(completion: searchCompletion)).start(completionHandler: {
            (response, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let response = response {
                guard let item = response.mapItems.first else {return}
                self.searchedLocation = item.placemark.title
                self.performSearch()

            }
        })
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

///Uses the MKLocalSeachCompleter to fill out the search result, which are used to populate the table view
extension SeachLocationViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results.filter { $0.subtitle != "Search Nearby" }
        self.searchTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search failed: \(error.localizedDescription)")
    }
}
