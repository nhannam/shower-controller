//
//  ClientService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 06/11/2024.
//

import Foundation
import SwiftData

enum ClientServiceError: Error {
    case clientExists
    case clientNotFound

}
@ModelActor
actor ClientService {
    static let ALL_PREDICATE = #Predicate<Client> { client in true }

    private func randomBytes(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status != errSecSuccess {
            preconditionFailure("failed to generate random bytes")
        }
        return Data(bytes)
    }
    
    func createClient(name: String) throws {
        try modelContext.transaction {
            let clientCount = try modelContext.fetchCount(
                FetchDescriptor(predicate: ClientService.ALL_PREDICATE)
            )
            
            guard clientCount == 0 else {
                throw ClientServiceError.clientExists
            }
            
            modelContext.insert(
                Client(
                    clientId: UUID(),
                    name: name,
                    secret: randomBytes(length: 4)
                )
            )
        }
    }
    
    func updateClientName(clientId: UUID, name: String) throws {
        try modelContext.transaction {
            let fetchDesciptor = FetchDescriptor(
                predicate: #Predicate<Client> { client in client.clientId == clientId}
            )
            
            let client = try modelContext.fetch(fetchDesciptor).first
            
            if let client {
                client.name = name
            } else {
                throw ClientServiceError.clientNotFound
            }
        }
    }
}
