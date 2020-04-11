//
//  ViewController.swift
//  DJ2
//
//  Created by Joseph Tebbett on 8/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import UIKit

// Controls the library view, a lists of all the user's songs
class SongsListViewController: UITableViewController {
    
    var songs: [Song] = []
    
    var searchResults: [Song] = []
    let searchController = UISearchController(searchResultsController: nil)
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search songs"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Demo code - no need to delete databse for regular use
        deleteDB()
        
        ArtistManager.shared.connect()
        AlbumManager.shared.connect()
        SongManager.shared.connect()
        TransitionManager.shared.connect()
        
        // Add demo songs to database
        SongManager.shared.insertSong(title: "Tour", artist: "Macky Gee", album: "Moments", year: 2018)
        SongManager.shared.insertSong(title: "Heavy and Dark (Bou & Simula Mix)", artist: "MC Bassman", album: "Heavy and Dark", year: 2019)
        SongManager.shared.insertSong(title: "Mr Happy", artist: "DJ Hazard", album: "Super Drunk", year: 2012)
        SongManager.shared.insertSong(title: "Bricks Don't Roll", artist: "DJ Hazard", album: "Bricks Don't Roll EP", year: 2014)
        SongManager.shared.insertSong(title: "If We Ever", artist: "High Contrast", album: "Tough Guys Don't Dance", year: 2007)
        reload()
        
        // Add demo transitions to database
        let tour = getSongByName(title: "Tour")!
        let mrh = getSongByName(title: "Mr Happy")!
        let bdr = getSongByName(title: "Bricks Don't Roll")!
        let iwe = getSongByName(title: "If We Ever")!
        
        TransitionManager.shared.insertTransition(from: tour, to: mrh)
        TransitionManager.shared.insertTransition(from: tour, to: bdr)
        TransitionManager.shared.insertTransition(from: tour, to: iwe)
        TransitionManager.shared.insertTransition(from: mrh, to: tour)
        TransitionManager.shared.insertTransition(from: mrh, to: bdr)
    }
    
    func reload() {
        // Get all songs from the databse and display
        songs = SongManager.shared.getSongs()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return searchResults.count
        }
        else {
            return songs.count
        }
    }
    
    
    // Sets up song sells for displays on table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = 72
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        
        let song: Song
        
        if isFiltering {
            song = searchResults[indexPath.row]
        }
        else {
            song = songs[indexPath.row]
        }
        
        cell.titleLabel.text = song.title
        cell.infoLabel.text = "\(song.artist.name) | \(song.album.title)"
        cell.yearLabel.text = String(song.year)

        
        return cell
    }
    
    // Called when user swipes to delete song, only available on the default view i.e. not for search results.
    // Deleting from search results is a feature I plan to add in the future
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SongManager.shared.delete(song: songs[indexPath.row])
            songs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Called when the user searches for a song. Songs with matching titles, artist names, album titles or year are returned
    func filterContentForSearchText(_ searchText: String) {
      searchResults = songs.filter { (song: Song) -> Bool in
        return song.title.range(of: searchText, options: .caseInsensitive) != nil
        || song.artist.name.range(of: searchText, options: .caseInsensitive) != nil
        || song.album.title.range(of: searchText, options: .caseInsensitive) != nil
        || String(song.year).range(of: searchText, options: .caseInsensitive) != nil
      }
      tableView.reloadData()
    }
    
    // Indicates that only non search result cells can be deleted
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isFiltering
    }
    
    // Deletes the database
    func deleteDB() {
        let filemManager = FileManager.default
        do {
            let databaseURL = try! FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("music.sqlite")
            try filemManager.removeItem(at: databaseURL as URL)
            //print("Database Deleted!")
        } catch {
            print("Error on Delete Database!!!")
        }
    }
    
    // Displays a dialogue box for the user to enter information for a new song
    @IBAction func buttonPopup(_ sender: UIButton) {
        let alertController = UIAlertController(title: "New Song", message: "Enter title, artist, album and year", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            
            let title = alertController.textFields?[0].text
            let artist = alertController.textFields?[1].text
            let album = alertController.textFields?[2].text
            let yearString = alertController.textFields?[3].text
            
            let year = Int(yearString!) ?? 0
            
            // Validates user input and displays an errror message if they have left fields empty or entered an invalid year
            if !title!.isEmpty && !artist!.isEmpty && !album!.isEmpty && year > 1900 && year <= Calendar.current.component(.year, from: Date()) {
                SongManager.shared.insertSong(title: title!, artist: artist!, album: album!, year: year)
                self.reload()
            }
            else {
                let invalidController = UIAlertController(title: "Invalid entry", message: "You didn't fill in all the fields, or you entered an invalid year", preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel) { (_) in }
                invalidController.addAction(dismissAction)
                self.present(invalidController, animated: true, completion: nil)
            
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Title"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Artist"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Album"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Year"
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    // Prepares the transition list view with the correct song
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TransitionSegue",
                let destination = segue.destination as? TransitionsListViewController,
                let index = tableView.indexPathForSelectedRow?.row {
            let song: Song
            
            if isFiltering {
                song = searchResults[index]
            }
            else {
                song = songs[index]
            }
            destination.title = song.title
            destination.fromSong = song
            destination.sections = [[song],[]]
        }
    }
    
    // Helper function to get song objects from 'songs' list
    func getSongByName(title: String) -> Song? {
        for song in songs {
            if song.title == title {
                return song
            }
        }
        return nil
    }
    
}

extension SongsListViewController: UISearchResultsUpdating {
    // Called when the user enters text in the search bar
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
  }
}

