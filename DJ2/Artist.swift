//
//  Artist.swift
//  DJ2
//
//  Created by Joseph Tebbett on 8/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import Foundation
import SQLite3

struct Artist {
    let id: Int
    let name: String
}

class ArtistManager {
    var database: OpaquePointer?
    
    static let shared = ArtistManager()
    
    private init() {
    }
    
    // Creates 'artists' table if it doesn't already exist
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
            CREATE TABLE IF NOT EXISTS artists (
                id INTEGER,
                name TEXT,
                PRIMARY KEY(id)
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
    }
    
    // Inserts a new artist into the 'artists' table and returns the new id of that artist
    func insertArtist(name: String) -> Int {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO artists (name) VALUES(?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: name).utf8String, -1, nil)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting artist")
            }
        }
        else {
            print("Error creating artist insert statement")
        }
        sqlite3_finalize(statement)
        
        return Int(sqlite3_last_insert_rowid(database))
    }
    
    // Gets the id of an artist given their name from the 'artists' table. Inserts artist into table if they are not already there, and returns the new id
    func getArtistID(name: String) -> Int {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "SELECT id  FROM artists WHERE name = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: name).utf8String, -1, nil)
            if  sqlite3_step(statement) != SQLITE_ROW {
                return insertArtist(name: name)
            }
        }
        else {
            print("Error creating artist select statement")
        }
        let id = Int(sqlite3_column_int(statement, 0))
        sqlite3_finalize(statement)
        return id
    }
}

