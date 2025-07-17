import CocoaLumberjack
import Foundation

class UploadImageManager {
    static let shared = UploadImageManager()

    private init() {}

    func uploadImageCall(
        imageView: UIImage,
        fileName: String, paramName: String,
        completion:
        @escaping (Result<String, NetworkError>) -> Void
    )
    {
        let hitUrlStr: String =
            ApiConfig.baseURL + ApiConfig.Endpoints.uploadImage
        print(hitUrlStr)
        guard let url = URL(string: hitUrlStr) else {
            print("Invalid URL.")
            return
        }

        let session = URLSession.shared

        // Generate boundary string using a unique per-app string
        let boundary = UUID().uuidString

        // Set the URLRequest to POST and to the specified URL
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"

        // Set Content-Type Header to multipart/form-data and set the boundary
        urlRequest.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type")

        var data = Data()

        // Add the image data to the raw HTTP request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileName)\"\r\n"
                .data(using: .utf8)!)
        data.append("Content-Type: image/jpg\r\n\r\n".data(using: .utf8)!)

        // Compress and resize the image before uploading
        if let compressedData = compressAndResizeImage(image: imageView) {
            data.append(compressedData)
        } else {
            print("Failed to convert image to JPEG.")
            return
        }

        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        // Send a POST request to the URL, with the data we created earlier
        session.uploadTask(with: urlRequest, from: data) {
            responseData, response, error in
            if let error = error {
                // Handle error with detailed log
                print("Error in image upload: \(error.localizedDescription)")
                if let nsError = error as NSError?,
                    nsError.code == NSURLErrorTimedOut
                {
                    print("Error: Request timed out.")
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response.")
                return
            }

            print("Image upload response: \(httpResponse.statusCode)")

            if (200...299).contains(httpResponse.statusCode) {
                if let responseData = responseData {
                    let res = String(decoding: responseData, as: UTF8.self)
                    DDLogDebug("MY Data is \(res)")
                    completion(.success(res))
                }
            } else {
                if let responseData = responseData {
                    let serverMessage =
                        String(data: responseData, encoding: .utf8)
                        ?? "No message from server."
                    print(
                        "Server error (status code: \(httpResponse.statusCode)): \(serverMessage)"
                    )
                    completion(
                        .failure(
                            .serverError(
                                statusCode: httpResponse.statusCode,
                                message: serverMessage)))
                    DDLogError(
                        "[ERROR]: \(NetworkError.serverError(statusCode: httpResponse.statusCode, message: serverMessage).description)"
                    )
                } else {
                    print(
                        "Server error (status code: \(httpResponse.statusCode)). No additional details."
                    )
                    completion(
                        .failure(
                            .serverError(
                                statusCode: httpResponse.statusCode,
                                message: "No additional details.")))
                }
            }
        }.resume()
    }

    // New helper function to resize and compress the image
    private func compressAndResizeImage(image: UIImage) -> Data? {
        // Resize the image to a smaller size (e.g., 800x800)
        let targetSize = CGSize(width: 300, height: 300)  // Set the desired size here
        let resizedImage = resizeImage(image: image, targetSize: targetSize)

        // Now compress the resized image
        if let compressedData = resizedImage.jpegData(compressionQuality: 0.03)
        {
            return compressedData
        }

        return nil
    }

    // Resize image to fit the target size
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(
            width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}
