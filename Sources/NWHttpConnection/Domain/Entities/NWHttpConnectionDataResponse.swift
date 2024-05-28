
import Foundation

public protocol NWHttpConnectionDataResponseType {
    var statusCode: Int? { get }
    var dataFormat: NWDataResponseType { get }
    var data: Data? { get }
}

public struct NWHttpConnectionDataResponse: NWHttpConnectionDataResponseType {
    public let statusCode: Int?
    public let dataFormat: NWDataResponseType
    public let data: Data?
}
