//
//  AddTransitionView.swift
//  DJ2
//
//  Created by Joseph Tebbett on 10/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import UIKit

// Controls view for adding transitions for a given song
class AddTransitionViewController: UITableViewController {
    
    var fromSong: Song!
    var prevTracks: [Song]!
    var sections: [[Song]]!
    let sectionHeaders = ["From", "To"]
    
    let prevTrack = 0
    let candidates = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()

    }
    
    // Adds all songs which don't already have a transition from the current song and which haven't already been transitioned from in the 'set'
    func reload() {
        sections = [[],[]]
        sections[prevTrack].append(fromSong)
        sections[candidates] = TransitionManager.shared.getPossisbleTransitions(from: fromSong)
        sections[candidates].removeAll(where: {prevTracks.contains($0) } )
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
    
    // Prevents the user from trying to add a transition from a song to itself
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
    
    // Updates the database with the new transition the user has created, and returns to the previous view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        TransitionManager.shared.insertTransition(from: fromSong, to: sections[candidates][indexPath.row])
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
    }
}
