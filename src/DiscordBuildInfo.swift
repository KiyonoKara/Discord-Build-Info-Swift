/*
 * Discord-Build-Info-Swift
 * Created by KaNguy - 02/27/2021
 */

// Imports
import UIKit
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

/**
 ## getAssets, function
        - Parameter url: String
        - Parameter completion: More-synchronous parameter that completes the function that is not to be used
        - Returns: String[]?]
    - Makes a request to get the needed asset(s)
*/
func getAssets(url: String, _ completion: @escaping (NSArray) -> ()) {
    let url = URL(string: url)!;
    let task = URLSession.shared.dataTask(with: url) {
        (data, response, error) in guard
            let data = data
        else {
            return
        }
        completion(matches(for: "/[A-Za-z0-9]*assets/[a-zA-z0-9]+.js", in: String(data: data, encoding: .utf8)!) as NSArray);
    }

    task.resume();
}

/**
 ## getClientBuildInfo, function
        - Parameter client: String (Type of release channel)
        - Parameter completion: More-synchronous parameter that completes the function that is not to be used
        - Returns: __SwiftDeferredNSArray or Array?
    - Gets the build number, hash, and ID based on the request of the asset file
*/
func getClientBuildInfo(client: String, _ completion: @escaping (NSArray) -> ()) {
    let clients = ["canary", "ptb", "stable"];

    var url: String = "";

    let element = clients.filter{ $0.lowercased() == client.lowercased() }.first!;
    if (element == "canary" || element == "ptb") {
        url = "https://\(element).discord.com";
    } else {
        url = "https://discord.com"
    }

    getAssets(url: "\(url)/app") {
        (array) in
        let asset = array.lastObject as! String;

        let asset_url = URL(string: "\(url)\(asset)")!;

        let task = URLSession.shared.dataTask(with: asset_url) {
            (data, response, error) in guard
                let data = data
            else {
                return
            }

            let final_data = String(data: data, encoding: .utf8);
        completion(matches(for: "Build Number: [0-9]+, Version Hash: [a-zA-z0-9]+", in: final_data ?? "Build Number: 00000, Version Hash: 0x0x0x0") as NSArray);
        }

        task.resume();
    }
}

func dictClientBuildInfo(info: String) -> Dictionary<String, Any> {
    var clientBuildDictionary: [String: String] = [:];

    let buildStrings = info.components(separatedBy: ",");
    let buildNumber: String = buildStrings[0].components(separatedBy: ":").last!;
    let buildHash: String = buildStrings[1].components(separatedBy: ":").last!;
    let buildID: String = String(buildHash.prefix(7));

    clientBuildDictionary["buildNumber"] = buildNumber;
    clientBuildDictionary["buildHash"] = buildHash;
    clientBuildDictionary["buildID"] = buildID;

    return clientBuildDictionary;
}

/**
  ## matches, function
        - Parameter regex: String
        - Parameter text: String
        - Returns String[]?
*/
func matches(for regex: String, in text: String) -> [String] {

    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        // Returns empty array and displays an error
        print("Invalid Regex: \(error.localizedDescription)")
        return []
    }
}

/**
  ## matchesForRegexInText, function
        - Parameter regex: String
        - Parameter text: String
        - Returns String[]?
*/
func matchesForRegexInText(regex: String!, text: String!) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex, options: [])
        let nsString = text as NSString
        guard let result = regex.firstMatch(in: text, options: [], range: NSMakeRange(0, nsString.length)) else {
            // If there are no matches
            return []
        }
        return (1 ..< result.numberOfRanges).map {
            nsString.substring(with: result.range(at: $0))
        }
    } catch let error as NSError {
        // Returns empty array and displays an error
        print("Invalid Regex: \(error.localizedDescription)")
        return []
    }
}

/**
 ## synchronousDataTask, extension of URLSession
        - Parameter urlrequest: URLRequest
        - Returns data, response, error
    - Extension of URLSession which makes a more synchronous data task with the request
*/
extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
}



getClientBuildInfo(client: "canary") {
    (data) in
        // Raw - Returns an array
        print(data)
        // Dictionary
        let dict = dictClientBuildInfo(info: data[0] as! String)
       print(dict)
}
