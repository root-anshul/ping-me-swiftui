//
//  ContentView.swift
//  Ping Me
//
//  Created by anshul on 18/11/23.
//

import SwiftUI
import Firebase
import FirebaseAuth

class FirebaseManager: NSObject {
    let auth: Auth
    static let shared = FirebaseManager()
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        
        super.init()
    }
}

struct LoginView: View {
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
//    @State var fname = ""
//    @State var lname = ""
    

    
    
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
                        }label:{
                          
                                Image(systemName: "person.fill")
                                .font(.system(size:64))
                                .padding()
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
    }
    private func handleAction(){
        if isLoginMode {
         //   print("Should log into Firebase with existing credentials")
            loginUser()
        } else{
            createNewAccount()
            
//        print("Register a new account inside of Firebase Auth and then store image in Storage somehow...")
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
            print("Successfully user created")
        }
            
        }
    }


struct ContentView_Previews1: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
