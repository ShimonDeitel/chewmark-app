import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var purchases: PurchaseManager
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var editingEntry: DentalEntry?

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    ContentUnavailableView("No entries yet", systemImage: "pawprint.fill", description: Text("Tap + to log your first entry."))
                } else {
                    List {
                        ForEach(store.entries) { entry in
                            Button {
                                editingEntry = entry
                            } label: {
                                HStack {
                                    Text(entry.date, style: .date)
                                        .font(Theme.headlineFont)
                                    Spacer()
                                    Text(entry.type)
                                        .foregroundStyle(Theme.accent)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("entryRow_\(entry.id.uuidString)")
                        }
                        .onDelete { offsets in
                            store.delete(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Chewmark")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddMore {
                            showingAdd = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addButton")
                }
            }
            .sheet(isPresented: $showingAdd) {
                EntryFormView(mode: .add)
                    .environmentObject(store)
            }
            .sheet(item: $editingEntry) { entry in
                EntryFormView(mode: .edit(entry))
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(purchases)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environmentObject(purchases)
            }
        }
    }
}

enum FormMode: Equatable {
    case add
    case edit(DentalEntry)
}

struct EntryFormView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    let mode: FormMode

    @State private var draftDate: Date = Date()
    @State private var draftType: String = ""
    @State private var draftNotes: String = ""

    init(mode: FormMode) {
        self.mode = mode
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $draftDate, displayedComponents: .date)
                    TextField("Type", text: $draftType)
                        .accessibilityIdentifier("field_type")
                    TextField("Notes", text: $draftNotes)
                        .accessibilityIdentifier("field_notes")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .accessibilityIdentifier("saveButton")
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func populateIfEditing() {
        if case .edit(let entry) = mode {
            draftDate = entry.date
            draftType = entry.type
            draftNotes = entry.notes
        }
    }

    private func save() {
        switch mode {
        case .add:
            let entry = DentalEntry(date: draftDate, type: draftType, notes: draftNotes)
            store.add(entry)
        case .edit(var entry):
            entry.date = draftDate
            entry.type = draftType
            entry.notes = draftNotes
            store.update(entry)
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
