//
//  FamilyMembersListView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct FamilyMembersListView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var familyMemberService: FamilyMemberService
    
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedMember: FamilyMember?
    @State private var showDeleteAlert = false
    
    var body: some View {
        List {
            Section {
                ForEach(familyMemberService.familyMembers) { member in
                    Button(action: {
                        selectedMember = member
                        showingEditSheet = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .fontWeight(.semibold)
                                
                                Text(member.relationship)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            selectedMember = member
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    showingAddSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Add Family Member")
                    }
                }
            }
        }
        .navigationTitle("Family Members")
        .onAppear {
            if let userId = authService.currentUser?.id {
                familyMemberService.setupFamilyMembersListener(for: userId)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFamilyMemberView()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let member = selectedMember {
                EditFamilyMemberView(familyMember: member)
            }
        }
        .alert("Delete Family Member", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let member = selectedMember {
                    familyMemberService.deleteFamilyMember(id: member.id) { _ in
                        // Handled by listener
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this family member? Any subscriptions associated with them will be kept but will no longer be assigned to a family member.")
        }
        .overlay(
            Group {
                if familyMemberService.isLoading {
                    LoadingView()
                }
            }
        )
    }
}

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var familyMemberService: FamilyMemberService
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let relationshipOptions = [
        "Spouse", "Partner", "Child", "Parent", "Sibling", "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                    
                    Picker("Relationship", selection: $relationship) {
                        Text("Select a relationship").tag("")
                        ForEach(relationshipOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section {
                    Button("Add Family Member") {
                        addFamilyMember()
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .overlay(
                Group {
                    if isLoading {
                        LoadingView()
                    }
                }
            )
            .alert(isPresented: .constant(errorMessage != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = nil
                    }
                )
            }
        }
    }
    
    private func addFamilyMember() {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "User not found"
            return
        }
        
        isLoading = true
        
        familyMemberService.addFamilyMember(name, relationship: relationship, userId: userId) { result in
            isLoading = false
            
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct EditFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyMemberService: FamilyMemberService
    
    var familyMember: FamilyMember
    
    @State private var name: String
    @State private var relationship: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let relationshipOptions = [
        "Spouse", "Partner", "Child", "Parent", "Sibling", "Other"
    ]
    
    init(familyMember: FamilyMember) {
        self.familyMember = familyMember
        
        _name = State(initialValue: familyMember.name)
        _relationship = State(initialValue: familyMember.relationship)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                    
                    Picker("Relationship", selection: $relationship) {
                        ForEach(relationshipOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        updateFamilyMember()
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
            .navigationTitle("Edit Family Member")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .overlay(
                Group {
                    if isLoading {
                        LoadingView()
                    }
                }
            )
            .alert(isPresented: .constant(errorMessage != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = nil
                    }
                )
            }
        }
    }
    
    private func updateFamilyMember() {
        isLoading = true
        
        let updatedMember = FamilyMember(
            id: familyMember.id,
            name: name,
            relationship: relationship
        )
        
        familyMemberService.updateFamilyMember(updatedMember) { result in
            isLoading = false
            
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}