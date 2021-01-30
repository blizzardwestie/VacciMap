//
//  CommentsView.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/30/21.
//

import SwiftUI
import FirebaseDatabase

struct CommentsView: View {
    var isTestingSite: Bool
    var siteID: String
    @State private var siteCommentsList = [Comment]()
    @State private var commentsLoaded = false
    @State private var commentsCount = 1 //will be set immediately when the view appears
    
    var body: some View {
        Form {
            Section(header: Text("Site Comments")){
                if commentsLoaded {
                    List(siteCommentsList, id: \.commentId){ comment in
                        Text(comment.commentText)
                    }
                }
                else {
                    if commentsCount > 0 {
                        Text("Loading comments...")
                    }
                    else { Text("No comments to display") }
                }
            }
        }.onAppear(perform: getSiteComments)
    }
    
    private func getSiteComments(){
        let commentsRef = Database.database().reference().child(isTestingSite ? "Testing Sites" : "Vaccination Sites").child(siteID).child(commentsKey)
        commentsRef.observeSingleEvent(of: .value){ snapshot in
            commentsCount = Int(snapshot.childrenCount)
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    if let comment = childSnapshot.value as? String {
                        let commentID = childSnapshot.key
                        let commentText = comment
                        siteCommentsList.append(Comment(commentId: commentID, commentText: commentText))
                    }
                    
                }
            }
            if commentsCount > 0 {
                commentsLoaded = true //once we've looped through all comments, display them.
            }
        }
    }
}

struct CommentsView_Previews: PreviewProvider {
    static var previews: some View {
        CommentsView(isTestingSite: true, siteID: "123")
    }
}

struct Comment {
    var commentId: String
    var commentText: String
}
