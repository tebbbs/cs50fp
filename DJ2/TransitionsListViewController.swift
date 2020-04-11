//
//  TransitionsListViewController.swift
//  DJ2
//
//  Created by Joseph Tebbett on 9/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import UIKit

class TransitionsListViewController: UITableViewController {
    
    var fromSong: Song!
    var sections: [[Song]]!
    let sectionHeaders = ["Tracks Played", "Up Next"]
    
    let history = 0
    let candidates = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
    }
    
    // Shows all possible transitions from a song, excluding songs already 'played'
    func reload() {
        sections[candidates] = TransitionManager.shared.getNextSongs(from: fromSong)
        let prevTracks = sections[history]
        sections[candidates].removeAll(where:  {prevTracks.contains($0) } )
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    // Prevents songs that are not possible transitions from being selected
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == candidates {
            return indexPath
        }
        else {
            return nil
        }
    }
    
    // Sets up song sells for displays on table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = 72
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell

        if indexPath.section == 0 {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }
        
        cell.titleLabel.text = sections[indexPath.section][indexPath.row].title
        cell.infoLabel.text = "\(sections[indexPath.section][indexPath.row].artist.name) | \(sections[indexPath.section][indexPath.row].album.title)"
        cell.yearLabel.text = String(sections[indexPath.section][indexPath.row].year)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    // Prevents songs from the 'Played' section from being deleted as they do not represent transitions
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section != history) {
            return true
        }
        else {
             return false
        }
    }
    
    // Deletes transitions for a given song
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            TransitionManager.shared.deleteTransition(from: fromSong, to: sections[candidates][indexPath.row])
            sections[candidates].remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Returns to the 'Library' view, discarding 'Tracks Played'
    @IBAction func backToLibrary() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    // Either prepares another TransitionsListViewController with the selected song, or segues to the AddTransitionViewController to allow the user to add more transitions for the current song
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "NextTransitionSegue",            
                let destination = segue.destination as? TransitionsListViewController,
                let index = tableView.indexPathForSelectedRow?.row {
            destination.title = sections[candidates][index].title
            destination.fromSong = sections[candidates][index]
            destination.sections = [sections[history], []]
            destination.sections[history].append(sections[candidates][index])
        }
        
        else if segue.identifier == "AddTransitionSegue",
                let destination = segue.destination as? AddTransitionViewController {
            
            navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "Back", style: .plain, target: nil, action: nil)
            destination.prevTracks = sections[history]
            destination.fromSong = fromSong
            destination.title = "Add new transition"
        }
    }
}
