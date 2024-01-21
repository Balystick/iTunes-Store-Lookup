/*
    iTunes Store Lookup
    
    Description: Application SwiftUI de recherche sur l'iTunes Store
    
    Auteur: Aurélien Chevalier
 */

import SwiftUI

struct MusicItem: Identifiable, Decodable {
    let trackId: Int
    var id: Int { trackId }
    let trackName: String
    let artistName: String
    let collectionName: String
    let artworkUrl60: String
}

struct ContentView: View {
    // Saisie et résultats de recherche
    @State private var searchTerm = ""
    @State private var searchResults: [MusicItem] = []
    
    // Alertes
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                // Saisie de la recherche
                TextField("Rechercher par artiste, album, chanson...", text: $searchTerm)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Lance la recherche
                Button("Rechercher") {
                    performSearch()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                // Affiche les résultats de la recherche
                List(searchResults) { result in
                    HStack {
                        // Affichage asynchrone de l'image
                        AsyncImage(url: URL(string: result.artworkUrl60)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            } else if phase.error != nil {
                                // Image de remplacement en cas d'échec de chargement de l'image ou d'erreur
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .foregroundColor(.gray)
                            } else {
                                // Indicateur de progression du chargement de l'image
                                ProgressView()
                                    .frame(width: 60, height: 60)
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        // Affichage du nom de la chanson
                        Text(result.trackName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                .navigationTitle("iTunes Store Lookup")
            }
            .background(Color(.systemGray6))
            // Alerte pour afficher les messages d'erreur
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Erreur"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // Effectue la recherche
    func performSearch() {
        // Encodage de la recherche et création de l'URL
        guard let searchTermEncoded = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(searchTermEncoded)&media=music")
        else {
            // Affichage d'une erreur si l'encodage de la recherche ou la création de l'URL échoue
            showAlert(message: "Terme de recherche ou URL invalide")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            // Gestion des erreurs réseau
            if let error = error {
                showAlert(message: "Erreur : \(error.localizedDescription)")
                return
            }

            // Traitement des données reçues
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let searchResults = try decoder.decode(SearchResults.self, from: data)
                    DispatchQueue.main.async {
                        // Mise à jour des résultats de la recherche
                        self.searchResults = searchResults.results
                    }
                } catch {
                    // Affichage d'une erreur si le décodage des données échoue
                    showAlert(message: "Erreur de décodage des données")
                }
            }
        }.resume()

        // Masquage du clavier après la recherche
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // Fonction pour afficher une alerte
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// Structure des résultats de recherche
struct SearchResults: Decodable {
    let results: [MusicItem]
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
