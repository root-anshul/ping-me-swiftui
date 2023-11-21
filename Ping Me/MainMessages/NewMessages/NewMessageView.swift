//
//  NewMessageView.swift
//  Ping Me
//
//  Created by anshul on 21/11/23.
//

import SwiftUI
import SDWebImageSwiftUI
class NewMessageViewModel: ObservableObject{
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    init(){
        fetchAllUser()
    }
    private func fetchAllUser(){
        FirebaseManager.shared.firestore.collection("users")
        
            .getDocuments{ documentsSnapshot, error in
                if let error = error{
                    print("Failed to fetch users:\(error)")
                    return
                }
                documentsSnapshot?.documents.forEach({ snapshot in
                    let data = snapshot.data()
                    let user = ChatUser(data: data)
                    if user.uid != FirebaseManager.shared.auth.currentUser?.uid{
                        self.users.append(.init(data: data))
                    }
                })
            }
    }
}


struct NewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = NewMessageViewModel()
    
    var body: some View {
        NavigationView{
            ScrollView{
                Text(vm.errorMessage)
                ForEach(vm.users){user in
                    Button{
                        presentationMode.wrappedValue
                            .dismiss()
                        didSelectNewUser(user)
                    }label: {
                        HStack (spacing: 16) {
                            WebImage(url: URL(string: user.profileImageurl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay (RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(.label),lineWidth: 2))
                            Text(user.fname)
                                .foregroundColor(Color(.label))
                            Spacer()
                        }.padding(.horizontal)
                        
                    }
                    Divider()
                    .padding(.vertical,8)
                }
            }.navigationTitle("New Message")
                .toolbar{
                    ToolbarItemGroup(placement: .navigationBarLeading){
                        Button{
                            presentationMode.wrappedValue.dismiss()
                        }label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}

struct NewMessage : PreviewProvider {
    static var previews: some View {
        //NewMessageView()
        MainMessagesVC()
     
    }
}
