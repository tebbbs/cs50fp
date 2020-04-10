//
//  ViewController.swift
//  DJ2
//
//  Created by Joseph Tebbett on 8/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import UIKit

class SongsListViewController: UITableViewController {
    
    var songs: [Song] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //searchBar.delegate = self
        
        deleteDB()
        ArtistManager.shared.connect()
        AlbumManager.shared.connect()
        SongManager.shared.connect()
        TransitionManager.shared.connect()

        print(SongManager.shared.insertSong(title: "Tour", artist: "Macky Gee", album: "Moments", year: 2018))
        print(SongManager.shared.insertSong(title: "Heavy and Dark (Bou & Simula Mix)", artist: "MC Bassman", album: "Heavy and Dark", year: 2019))
        print(SongManager.shared.insertSong(title: "Mr Happy", artist: "DJ Hazard", album: "Super Drunk", year: 2012))
        print(SongManager.shared.insertSong(title: "Bricks Don't Roll", artist: "DJ Hazard", album: "Bricks Don't Roll EP", year: 2014))
        print("Hazard artist id: \(ArtistManager.shared.getArtistID(name: "DJ Hazard"))")
        
        SongManager.shared.insertSong(title: "If We Ever", artist: "High Contrast", album: "Tough Guys Don't Dance", year: 2007)
        reload()
        
        
        let tour = songs[0]
        let mrh = songs[2]
        let bdr = songs[3]
        
        let iwe = songs[4]
        
        
        TransitionManager.shared.insertTransition(from: tour, to: mrh)
        TransitionManager.shared.insertTransition(from: tour, to: bdr)
        TransitionManager.shared.insertTransition(from: tour, to: iwe)
        TransitionManager.shared.insertTransition(from: mrh, to: tour)
        TransitionManager.shared.insertTransition(from: mrh, to: bdr)
    }
    
    func reload() {
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
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = 72
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        
        cell.titleLabel.text = songs[indexPath.row].title
        cell.infoLabel.text = "\(songs[indexPath.row].artist.name) | \(songs[indexPath.row].album.title)"
        cell.yearLabel.text = String(songs[indexPath.row].year)

        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SongManager.shared.delete(song: songs[indexPath.row])
            songs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    /*
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Empty list of search results
        searchResults = []
        for song in songs {
            if song.title.range(of: searchText, options: .caseInsensitive) != nil
            || song.artist.name.range(of: searchText, options: .caseInsensitive) != nil
            || song.album.title.range(of: searchText, options: .caseInsensitive) != nil
            || String(song.year).range(of: searchText, options: .caseInsensitive) != nil {
                // Match found, add to search results
                searchResults.append(song)
            }
        }
        
        // Reload view
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    */
    
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
            print("Database Deleted!")
        } catch {
            print("Error on Delete Database!!!")
        }
    }
    

    @IBAction func buttonPopup(_ sender: UIButton) {
        let alertController = UIAlertController(title: "New Song", message: "Enter title, artist, album and year", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            
            let title = alertController.textFields?[0].text
            let artist = alertController.textFields?[1].text
            let album = alertController.textFields?[2].text
            let yearString = alertController.textFields?[3].text
            
            let year = Int(yearString!) ?? 0
            
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TransitionSegue",
                let destination = segue.destination as? TransitionsListViewController,
                let index = tableView.indexPathForSelectedRow?.row {
            destination.title = songs[index].title
            destination.fromSong = songs[index]
            destination.sections = [[songs[index]],[]]
        }
    }
}

