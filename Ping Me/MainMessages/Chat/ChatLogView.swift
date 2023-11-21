//
//  ChatLogView.swift
//  Ping Me
//
//  Created by anshul on 21/11/23.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore



struct FirebaseConstants{
    static let fromID = "fromId"
    static let toId = "toId"
    static let text = "text"
}


struct ChatMessage: Identifiable{
    var id: String { documentId }
    let documentId: String
    let fromId, toId, text: String
    
    init(documentId: String ,data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromID] as? String ?? ""
        self.toId = data[FirebaseConstants.toId]as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
    
}

class ChatLogViewModel: ObservableObject{
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessage = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        fetchMessages()
    }
    
    private func fetchMessages(){
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else{return}
        guard let toID = chatUser?.uid else {return}
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromID)
            .collection(toID)
            .order(by: "timestamp")
            .addSnapshotListener{ querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen formessages:\(error)"
                    print (error)
                    return
                }
                querySnapshot?.documentChanges.forEach({change in
                    if change.type == .added{
                        let data = change.document.data()
                        self.chatMessage.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
                DispatchQueue.main.async{
                    self.count += 1
                }
                
                

            }
    }
    
    func handleSend(){
        print(chatText)
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else{return}
        guard let toID = chatUser?.uid else {return}
        let document =  FirebaseManager.shared.firestore.collection("messages")
            .document(fromID)
            .collection(toID)
            .document()
        let messageData = [FirebaseConstants.fromID: fromID, FirebaseConstants.toId: toID,FirebaseConstants.text :self.chatText, "timestamp": Timestamp()] as [String : Any]
        
        document.setData(messageData){error in
            if let error = error {
                self.errorMessage = "not saved into Firestore:\(error)"
                    return
            }
            print("successfully saved current user sending message")
            self.chatText = ""
            self.count += 1
        }
        let reciepientMessageDoc =  FirebaseManager.shared.firestore.collection("messages")
             .document(toID)
             .collection(fromID)
             .document()
        reciepientMessageDoc.setData(messageData){error in
            if let error = error {
                self.errorMessage = "not saved into Firestore:\(error)"
                return
            }
            print("recirpient saved message as well")
        }
    }
    @Published var count = 0
    
}


struct ChatLogView: View {
    
    let chatUser: ChatUser?
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        VStack{
          MessageView
         ChatBottomBar
        }
        .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarItems(trailing: Button(action: {
//                vm.count += 1
//            }, label: {
//                Text("count\(vm.count)")
//            }))
    }
    static let emptyScrollToString = "Empty"
    private var MessageView: some View{
        VStack{
            ScrollView{
                ScrollViewReader{ScrollViewProxy in
                    VStack{
                        ForEach(vm.chatMessage){ message in
                            Messageview(message: message)
                            
                        }
                        HStack{Spacer()}
                            .id(Self.emptyScrollToString)
                    }
                    .onReceive(vm.$count) { _ in
                        withAnimation(.easeOut(duration: 0.5)){
                            ScrollViewProxy.scrollTo(Self.emptyScrollToString,anchor: .bottom)
                        }
                    }
                   
                       
                }
                
            }.background(Color(.init(white: 0.95,alpha: 1)))
        }
    }
    
    struct Messageview: View {
        let message: ChatMessage
        var body: some View {
            VStack{
                if message.fromId == FirebaseManager.shared.auth.currentUser?.uid{
                    HStack{
                        Spacer()
                        HStack{
                            Text(message.text)
                                .foregroundStyle(.white)
                            
                        }.padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                }else{
                    HStack{
                        HStack{
                            Text(message.text)
                                .foregroundStyle(.black)
                            
                        }.padding()
                            .background(Color.white)
                            .cornerRadius(8)
                        Spacer()
                    }
                    
                }
            }.padding(.horizontal)
                .padding(.top, 8)
        }
    }
    private var ChatBottomBar : some View{
        HStack(spacing: 16){
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
           
            
            TextField( "Message", text: $vm.chatText)
            
            Button{
                vm.handleSend()
            }label:{
            Text("Send")
                .foregroundStyle(.white)
        }
            .padding(.horizontal)
            .padding(.vertical,8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical,8)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
//            ChatLogView(chatUser: .init(data: ["uid": "x0648hWWOsNenNl0yBUlVWP2J713", "email": "test@gmail.com"]))
//        }
        MainMessagesVC()
    }
}
