//
//  Song.swift
//  DJ2
//
//  Created by Joseph Tebbett on 8/4/20.
//  Copyright © 2020 CS50. All rights reserved.
//

import Foundation
import SQLite3

struct Song: Equatable {
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: Int
    let title: String
    let artist: Artist
    let album: Album
    // find better datatype for year
    let year: Int
}

class SongManager {
    var database: OpaquePointer?
    
    static let shared = SongManager()
    
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
            CREATE TABLE IF NOT EXISTS songs (
                id INTEGER,
                title TEXT,
                artist_id INTEGER,
                album_id INTEGER,
                year NUMERIC,
                PRIMARY KEY(id),
                FOREIGN KEY(artist_id) REFERENCES artists(id),
                FOREIGN KEY(album_id) REFERENCES albums(id)
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(database)!))")
        }
       
    }
        
    func insertSong(title: String, artist: String, album: String, year: Int) -> Int{
        let artistID = ArtistManager.shared.getArtistID(name: artist)
        // We will assume that song year = album year for this app
        let albumID = AlbumManager.shared.getAlbumID(title: album, artist: artist, year: year)
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "INSERT INTO songs (title, artist_id, album_id, year) VALUES(?, ?, ?, ?)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, NSString(string: title).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(artistID))
            sqlite3_bind_int(statement, 3, Int32(albumID))
            sqlite3_bind_int(statement, 4, Int32(year))
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting song")
            }
        }
        else {
            print("Error creating song insert statement")
        }
        sqlite3_finalize(statement)
        
        return Int(sqlite3_last_insert_rowid(database))
    }
    
    func getSongs() -> [Song] {
        connect()
        var result: [Song] = []
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            """
            SELECT songs.id, songs.title, artists.id, artists.name, albums.id, albums.title, songs.year FROM
            songs JOIN artists ON songs.artist_id = artists.id JOIN
            albums ON songs.album_id = albums.id
            
            """,
            -1,
            &statement,
            nil
            ) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let year = Int(sqlite3_column_int(statement, 6))
                    let artist = Artist(id: Int(sqlite3_column_int(statement, 2)), name: String(cString: sqlite3_column_text(statement, 3)))
                    result.append(Song(
                        id: Int(sqlite3_column_int(statement, 0)),
                        title: String(cString: sqlite3_column_text(statement, 1)),
                        artist: artist,
                        album: Album(id: Int(sqlite3_column_int(statement, 4)), title: String(cString: sqlite3_column_text(statement, 5)), artist: artist, year: year),
                        year: year
                    ))
                }
            }
        
        sqlite3_finalize(statement)
        return result
    }
    
    func delete(song: Song) {
        connect()
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(
            database,
            "DELETE FROM songs WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(song.id))
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error deleting song")
            }
        }
        else {
            print("Error creating song delete statement")
        }
        sqlite3_finalize(statement)
        
    }
    
    func parseSong(statement: OpaquePointer) -> Song {
        let year = Int(sqlite3_column_int(statement, 6))
        let artist = Artist(id: Int(sqlite3_column_int(statement, 2)), name: String(cString: sqlite3_column_text(statement, 3)))
        let album = Album(id: Int(sqlite3_column_int(statement, 4)), title: String(cString: sqlite3_column_text(statement, 5)), artist: artist, year: year)
        let song = Song(
            id: Int(sqlite3_column_int(statement, 0)),
            title: String(cString: sqlite3_column_text(statement, 1)),
            artist: artist,
            album: album,
            year: year
        )
        return song
    }

}

