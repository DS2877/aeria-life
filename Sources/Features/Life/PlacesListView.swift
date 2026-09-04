import CoreLocation
import SwiftData
import SwiftUI

/// Places power Life Mode inference (`LifeModeEngine.nearestKnownPlace`) —
/// this screen is intentionally minimal since most users only ever need
/// "home" and "work" defined.
struct PlacesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.name) private var places: [Place]
    @State private var isPresentingAdd = false

    var body: some View {
        Group {
            if places.isEmpty {
                EmptyStateView(
                    symbolName: "mappin.circle",
                    title: "No places yet",
                    message: "Add Home and Work so Aeria can tell where you are."
                )
                .padding(.top, Metrics.spacingXXL)
            } else {
                List {
                    ForEach(places) { place in
                        HStack {
                            Image(systemName: place.category == .home ? "house.fill" : place.category == .work ? "briefcase.fill" : "mappin.circle.fill")
                                .foregroundStyle(Palette.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name).foregroundStyle(Palette.textPrimary)
                                if !place.address.isEmpty {
                                    Text(place.address).font(AeriaFont.caption).foregroundStyle(Palette.textSecondary)
                                }
                            }
                        }
                        .listRowBackground(Palette.canvas)
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.delete(places[index]) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Places")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddPlaceSheet()
        }
    }
}

private struct AddPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var location = LocationContextProvider()

    @State private var name = ""
    @State private var category: PlaceCategory = .home
    @State private var address = ""
    @State private var useCurrentLocation = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(PlaceCategory.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                TextField("Address (optional)", text: $address)

                Section {
                    Toggle("Use my current location", isOn: $useCurrentLocation)
                    if useCurrentLocation && location.currentLocation == nil {
                        Text("Waiting for location…")
                            .font(AeriaFont.caption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                } footer: {
                    Text("This lets Aeria recognize when you're here for Life Mode — otherwise this is just a name and address.")
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                location.requestAccess()
                location.refreshLocation()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let place = Place(name: name, category: category, address: address)
        if useCurrentLocation, let current = location.currentLocation {
            place.latitude = current.coordinate.latitude
            place.longitude = current.coordinate.longitude
        }
        modelContext.insert(place)
        dismiss()
    }
}
