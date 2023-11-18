//
//  ContentView.swift
//  Ping Me
//
//  Created by anshul on 18/11/23.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage

class FirebaseManager: NSObject {
    let auth: Auth
    let storage: Storage
    
    static let shared = FirebaseManager()
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        super.init()
    }
}

struct LoginView: View {
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
//    @State var fname = ""
//    @State var lname = ""
    @State var shouldShowImagePicker = false

    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing:25){
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text ("Login" )
                            .tag (true)
                        Text ("Create Account")
                            .tag (false)
                    }.pickerStyle(SegmentedPickerStyle())
                        .padding()
                    
                    if !isLoginMode{
                        
                        Button{
                            shouldShowImagePicker.toggle()
                        }label:{
                            VStack{
                                if let image = self.image{
                                    
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 128,height: 128)
                                        .cornerRadius(64)
                                }
                                else{
                                    Image(systemName: "person.fill")
                                    .font(.system(size:64))
                                    .padding()
                                    .foregroundColor (Color (.label))
                                }
                            }
                            .overlay (RoundedRectangle(cornerRadius: 64)
                                .stroke(Color.black, lineWidth:3)
                                      )
                        }

                    }
                    Group{
                        
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            
                        SecureField("Password", text: $password)
                        
                    }.padding (12)
                     .background(Color.white)
            
                    
                    Button{
                        handleAction()
                    }label: {
                        HStack{
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                                Spacer()
                                .font(.system(size: 14, weight: .semibold))
                        }.background(Color.blue)
                    }
                 
                }
                .padding()
                
        }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
            ImagePicker(image: $image)
        }
    }
    @State var image: UIImage?
    
    private func handleAction(){
        if isLoginMode {
            loginUser()
        } else{
            createNewAccount()
                        }
        }
    
    private func loginUser() {
        
        
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print ("Failed to login user:", err)
                self.loginStatusMesgage = "Failed to login user: \(err)"
                return
            }
            print("Successfully logged in as user: \(result?.user.uid ?? "") " )
            self.loginStatusMesgage = "Successfully logged in as user: \(result?.user.uid ?? "")"
        }
    }
    @State var loginStatusMesgage = ""
    
    //FIREBASE LOGIN
    private func createNewAccount(){
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password)
        { result, err in
            if let err = err{
                print ("Failed to create user: ", err)
                return
            }
            print("Successfully user created: \(result?.user.uid ?? "")")
            
            self.loginStatusMesgage = "Successfully created user:\(result?.user.uid ?? "") "
         
            self.persistImageTostorage()
        }
       
        }
        private func persistImageTostorage(){
           // let filename = UUID().uuidString
            guard let uid = FirebaseManager.shared.auth.currentUser?.uid
            else { return }
            let ref = FirebaseManager.shared.storage.reference(withPath: uid)
            guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else{return}
            
            ref.putData(imageData, metadata: nil) {
                metadata, err in
                if let err = err{
                    self.loginStatusMesgage = "Failed to push image to storage\(err)"
                    return
                }
                ref.downloadURL{url, err in
                    if let err = err{
                        self.loginStatusMesgage = "Failed to retrive downloadURL:\(err)"
                        return
                    }
                    self.loginStatusMesgage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                    print(url?.absoluteString)
                }
                
            }
        }
    }


struct ContentView_Previews1: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
