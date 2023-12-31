//
//  MainMessagesVC.swift
//  Ping Me
//
//  Created by anshul on 19/11/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct RecentMessage: Identifiable {
    var id:String{
        documentId
    }
    
    let documentId: String
    let text, email: String
    let fromId, toId: String
    let profileImageUrl: String
    let timestamp: Timestamp
    
    init(documentId:String, data:[String:Any]){
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.profileImageUrl = data["profileImageurl"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}

class MainMessages: ObservableObject{
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    
    init(){
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedout = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        
        fetchRecentMessages()
    }
    @Published var recentMessages = [RecentMessage]()
    
    private func fetchRecentMessages(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else{return}
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener{querySnapshot,error in
                    if let error = error{
                        self.errorMessage = "Failed to listen for recent messages\(error)"
                        print(error)
                        return
                    }
                querySnapshot?.documentChanges.forEach({ change in
  
                        let docId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.documentId == docId
                    }){
                        self.recentMessages.remove(at: index)
                    }
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at:0)
                })
                   
                }
                        
            
    }
    
    
     func fetchCurrentUser(){
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else{
            
            self.errorMessage = "no firebase"
            return
        }
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).getDocument{ snapshot, error in
                if let error = error{
                    self.errorMessage = "Failed to fetch current user:\(error)"
                    print("Failed to fetch current user:", error)
                    return
                }
                self.errorMessage = "123"
                guard let data = snapshot?.data() else {
                    self.errorMessage = "no data found"
                    return
                }
                // self.errorMessage = "Data: \(data.description)"
                self.chatUser = .init(data: data)
                
                
                
                // self.errorMessage = chatUser.profileImageurl
            }
        
    }
    @Published var isUserCurrentlyLoggedout = false
    func handlesignout(){
        isUserCurrentlyLoggedout.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
}


struct MainMessagesVC: View {
    
    @State var shouldshowlogout = false
    @ObservedObject private var vm = MainMessages()
    @State var shouldNavigateToChatLogView = false
    var body: some View {
        NavigationView{
            VStack {
//               Text("USER: \(vm.chatUser?.uid ?? "")")
                // custom nav bar
                customNavbar
                // custom message View
                Messageview
                NavigationLink("", isActive:
                                $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    private var customNavbar: some View{
        HStack(spacing: 16) {
            WebImage(url:URL(string: vm.chatUser?.profileImageurl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50,height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay (RoundedRectangle (cornerRadius:44)
                    . stroke(Color(.label), lineWidth: 1)
                )
//           Image(systemName: "person.fill")
//                .font(.system(size: 34, weight: .heavy))
            
            VStack(alignment: .leading, spacing: 4) {
            
                
                Text ("\(vm.chatUser?.fname ?? "")" )
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor (.green)
                        .frame (width: 14, height: 14)
                    Text ("online")
                        .font (.system(size: 12))
                        .foregroundColor (Color (.lightGray))
                }
            }
            Spacer ()
            Button{
                shouldshowlogout.toggle()
            }
        label:{
            Image (systemName:"gear")
                .font(.system(size: 24,weight: .bold))
                .foregroundColor(Color(.label))
        }
           
        }
        .padding()
        .actionSheet(isPresented: $shouldshowlogout) {
            .init(title: Text("Settings"), message:
                    Text ("What do you want to do?"), buttons:[
                        .destructive(Text ("Sign Out"), action: {
                            print ("handle sign out")
                            vm.handlesignout()
                        }),
                        .cancel()
                        ])
        
                }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedout, onDismiss: nil){
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedout = false
                self.vm.fetchCurrentUser()
            })
          
        }
   
}
    
    private var Messageview: some View{
        
        ScrollView{
            ForEach(vm.recentMessages){ recentMessage in
                VStack{
                    NavigationLink {
                        Text("Destination")
                    } label: {
                        HStack(spacing: 16){
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64,height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color.black,lineWidth:1))
                                .shadow(radius: 5)
                                

                            VStack(alignment: .leading,spacing: 8){
                                Text(recentMessage.email)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text(recentMessage.text)
                                    .font (.system(size: 14))
                                    .foregroundColor (Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                                }
                            
                                Spacer()
//                            Text(recentMessage.timestamp.description)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                    }

               
                        Divider()
                        .padding(.vertical,8)
                    }.padding(.horizontal)
            }.padding(.bottom, 50)
          
        }
    }
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View{
        Button {
            shouldShowNewMessageScreen.toggle()
        }label: {
            HStack{
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16,weight:.bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
                .background(Color.blue)
                .cornerRadius(32)
                .padding(.horizontal)
                .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            NewMessageView(didSelectNewUser: { user
                in print(user.fname)
                self.shouldNavigateToChatLogView.toggle();         self.chatUser = user
            })
        }
    }
    @State var chatUser: ChatUser?
}



#Preview {
    MainMessagesVC()
       // .preferredColorScheme(.dark)
}
