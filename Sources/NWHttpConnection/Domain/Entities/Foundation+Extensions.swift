
import Foundation

public extension Array {
    subscript(safeAt index: Int) -> Element? {
        if index >= count || index < 0 {
            return nil
        }
        return self[index]
    }
}
