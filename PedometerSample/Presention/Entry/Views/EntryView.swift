//
//  EntryView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import SwiftUI

class EntryViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userWeight: String = ""
    @Published var shouldEntry: Bool = false
    @Published var showError: Bool = false
    
    var weightValue: Double? {
        Double(userWeight)
    }
    
    func submit() {
        guard !userName.isEmpty,
              !userWeight.isEmpty,
              let weight = weightValue,
              weight > 0 else {
            showError = true
            shouldEntry = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showError = false
            }
            return
        }
        
        let newUser = User(nickName: userName, userWeight: weight)
        CurrentUser.shared.user = newUser
        shouldEntry = true
        showError = false
    }
}

struct EntryView: View {
    @StateObject var vm = EntryViewModel()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            VStack(alignment: .leading) {
                Text("ニックネームを入力してください")
                TextField("", text: $vm.userName)
                    .padding()
                    .background(Color(.systemGray6))
                
                Text("体重を入力してください")
                TextField("", text: $vm.userWeight)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                
                if vm.showError {
                    Text("正しく入力してください")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Spacer()
                
                Button(action: {
                    //ネームと体重をViewModelに渡す
                    vm.submit()
                }) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 50)
                        .cornerRadius(8)
                        .overlay(
                            Text("エントリー")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 300)
            .padding(.horizontal)
            .focused($isFocused)
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $vm.shouldEntry) {
            MainTabView()
        }
        .onTapGesture {
            isFocused = false
        }
    }
}

#Preview {
    EntryView()
}
