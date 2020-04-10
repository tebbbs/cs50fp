//
//  Album.swift
//  DJ2
//
//  Created by Joseph Tebbett on 8/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import Foundation
import SQLite3

struct Album {
    let id: Int
    let title: String
    let artist: Artist
    // Find better datatype for year
    let year: Int
}

class AlbumManager {
    var database: OpaquePointer?
    
    static let shared = AlbumManager()
    
    private init() {
    }
    
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
            CREATE TABLE IF NOT EXISTS albums (
                id INTEGER,
                title TEXT,
                artist_id INTEGER,
                year NUMERIC,
                PRIMARY KEY(id),
                FOREIGN KEY(artist_id) REFERENCES artists(id)
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString:  sqlite3_errmsg(database)!))")
        }
    }
    
    func insertAlbum(title: String, artist: String, year: Int) -> Int {
        let artistID = ArtistManager.shared.getArtistID(name: artist)
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO albums (title, artist_id, year) VALUES(?, ?, ?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: title).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(artistID))
            sqlite3_bind_int(statement, 3, Int32(year))
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting album")
            }
        }
        else {
            print("Error creating album insert statement")
        }
        sqlite3_finalize(statement)
        
        return Int(sqlite3_last_insert_rowid(database))
        
    }
    
    func getAlbumID(title: String, artist: String, year: Int) -> Int {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "SELECT id FROM albums WHERE title = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: title).utf8String, -1, nil)
            if  sqlite3_step(statement) != SQLITE_ROW {
                return insertAlbum(title: title, artist: artist, year: year)
            }
        }
        else {
            print("Error creating Album select statement")
        }
        let id = Int(sqlite3_column_int(statement, 0))
        sqlite3_finalize(statement)
        return id
    }
}
