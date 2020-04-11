//
//  Transition.swift
//  DJ2
//
//  Created by Joseph Tebbett on 8/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import Foundation
import SQLite3

struct Transition {
    let id: Int
    let from: Song
    let to: Song
}

class TransitionManager {
    var database: OpaquePointer?
    
    static let shared = TransitionManager()
    
    private init() {
    }
    
    // Creates 'transitions' table if it doesn't already exist
    func connect() {
        if database != nil {
            return
        }
    
        let databaseURL = try! FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("music.sqlite")
    
        if sqlite3_open(databaseURL.path, &database) != SQLITE_OK {
            print("Error opening database")
            return
        }
        if sqlite3_exec(
            database,
            """
            CREATE TABLE IF NOT EXISTS transitions (
                id INTEGER,
                from_id INTEGER,
                to_id INTEGER,
                PRIMARY KEY(id),
                FOREIGN KEY(from_id) REFERENCES songs(id) ON DELETE CASCADE,
                FOREIGN KEY(to_id) REFERENCES songs(id) ON DELETE CASCADE
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString:  sqlite3_errmsg(database)!))")
        }
    }
    
    // Insets a transition from song 'from' to song 'to' into the databse
    func insertTransition(from: Song, to: Song) -> Int {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO transitions (from_id, to_id) VALUES(?, ?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(from.id))
            sqlite3_bind_int(statement, 2, Int32(to.id))

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting transition")
            }
        }
        else {
            print("Error creating transition insert statement")
        }
        sqlite3_finalize(statement)
        
        return Int(sqlite3_last_insert_rowid(database))
    }
    
    // Deletes a transition from song 'from' to song 'to' from the databse
    func deleteTransition(from: Song, to: Song) {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "DELETE FROM transitions WHERE from_id = ? AND to_id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(from.id))
            sqlite3_bind_int(statement, 2, Int32(to.id))

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting transition")
            }
        }
        else {
            print("Error creating transition delete statement")
        }
        sqlite3_finalize(statement)
        
    }
    
    // Returns a list of songs that the song 'from' transitions to, according to the databse, ordered by the song's title
    func getNextSongs(from: Song) -> [Song] {
        connect()
        var result: [Song] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            """
            SELECT songs.id, songs.title, artists.id, artists.name, albums.id, albums.title, songs.year FROM
            songs JOIN artists ON songs.artist_id = artists.id JOIN
            albums ON songs.album_id = albums.id JOIN
            transitions ON songs.id = transitions.to_id
            WHERE transitions.from_id = ?
            ORDER BY songs.title ASC
            """,
            -1,
            &statement,
            nil
            ) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(from.id))
                while sqlite3_step(statement) == SQLITE_ROW {
                    let song = SongManager.shared.parseSong(statement: statement!)
                    result.append(song)
                }
            }
        
        sqlite3_finalize(statement)
        return result
    }
    
    // 'Opposite' of getNextSongs, returns a list of all songs that song 'from' has not yet been recorded as transitioning to
    func getPossisbleTransitions(from: Song) -> [Song] {
        connect()
        var result: [Song] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            """
            SELECT songs.id, songs.title, artists.id, artists.name, albums.id, albums.title, songs.year FROM
            songs JOIN artists ON songs.artist_id = artists.id JOIN
            albums ON songs.album_id = albums.id
            WHERE songs.id NOT IN (SELECT to_id FROM transitions WHERE from_id = ?)
            ORDER BY songs.title ASC
            """
            ,
            -1,
            &statement,
            nil
            ) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(from.id))
            
                while sqlite3_step(statement) == SQLITE_ROW {
                    let song = SongManager.shared.parseSong(statement: statement!)
                    result.append(song)
                }
            }
        
        sqlite3_finalize(statement)
        return result
    }
    
    
}
