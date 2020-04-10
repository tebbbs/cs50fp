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
    let history = 0
    let candidates = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // allSongs[0] = history, allSongs[1] = nextSongs
        //allSongs[0].append(fromSong)
        
        reload()
        //for song in nextSongs {
        for song in sections[candidates] {
            print(song.title)
        }
    }
    
    func reload() {
        sections[candidates] = TransitionManager.shared.getNextSongs(from: fromSong)
        let prevTracks = sections[history]
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
        if section == history {
            return "Tracks played"
        }
        else if section == candidates {
            return "Up next"
        }
        else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section != history) {
            return true
        }
        else {
             return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            TransitionManager.shared.deleteTransition(from: fromSong, to: sections[candidates][indexPath.row])
            sections[candidates].remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == candidates {
            return indexPath
        }
        else {
            return nil
        }
    }
    
    @IBAction func backToLibrary() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
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
        }
    }
}
