//
//  File.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import Foundation

class APIService {
    private let logQuery: Bool = true
    private let logResponses: Bool = true

    private let session: URLSession
    private let env: Env
    
    init(env: Env, session: URLSession = .shared) {
        self.env = env
        self.session = session
    }

    func baseUrl() -> String {
        return env.apiBaseUrl
    }

    func post<T: Codable, U: Codable>(toEndpoint: String, payload: T) async throws -> U? {
        do {
            guard let url = URL(string: "\(env.apiBaseUrl)\(toEndpoint)") else { throw NetworkError.badUrl }
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            request.httpMethod = "POST"
            let encoder = JSONEncoder()
            let data = try encoder.encode(payload)
            request.httpBody = data
            
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }

            guard response.statusCode >= 200 && response.statusCode < 300 else { throw NetworkError.badStatus }

            guard let decodedResponse = try? JSONDecoder().decode(U.self, from: responseData) else { throw NetworkError.failedToDecodeResponse }

            return decodedResponse
        } catch NetworkError.badUrl {
            print("There was an error creating the URL")
        } catch NetworkError.badResponse {
            print("Did not get a valid response")
        } catch NetworkError.badStatus {
            print("Did not get a 2xx status code from the response")
        } catch NetworkError.failedToDecodeResponse {
            print("Failed to decode response into the given type")
        } catch {
            print("An error occured downloading the data")
        }
        return nil
    }

    func fetchData<T: Codable>(fromEndpoint: String) async throws -> T? {
        guard let downloadedData: T = await self.downloadData(fromEndpoint: fromEndpoint) else {return nil}
        return downloadedData
    }

    private func downloadData<T: Codable>(fromEndpoint: String) async -> T? {
        do {
            guard let url = URL(string: "\(env.apiBaseUrl)\(fromEndpoint)") else { throw NetworkError.badUrl }

            if logQuery {
                print("******** Query ********")
                print(url)
            }

            let (data, response) = try await URLSession.shared.data(from: url)

            if logResponses {
                print(" Reponse :")
                print("\(String(bytes: data, encoding: .utf8) ?? "No data")")
            }

            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            guard response.statusCode >= 200 && response.statusCode < 300 else { throw NetworkError.badStatus }
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch NetworkError.badUrl {
            print("There was an error creating the URL")
        } catch NetworkError.badResponse {
            print("Did not get a valid response")
        } catch NetworkError.badStatus {
            print("Did not get a 2xx status code from the response")
        } catch NetworkError.failedToDecodeResponse {
            print("Failed to decode response into the given type")
        } catch {
            print("An error occured downloading the data: \(error)")
        }

        return nil
    }
}


