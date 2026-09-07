import Foundation

enum Format {

    static func fixed(_ value: Double, _ places: Int = 4) -> String {
        String(format: "%.\(places)f", value)
    }

    static func scientific(_ value: Double) -> String {
        value == 0 ? "0" : String(format: "%.3e", value)
    }

    static func heading(_ title: String) -> String {
        "\n" + title + "\n" + String(repeating: "-", count: title.count)
    }

    static func pad(_ text: String, _ width: Int) -> String {
        text.count >= width ? text : text + String(repeating: " ", count: width - text.count)
    }

    static func padLeft(_ text: String, _ width: Int) -> String {
        text.count >= width ? text : String(repeating: " ", count: width - text.count) + text
    }

    static func row(_ cells: [String], widths: [Int]) -> String {
        zip(cells, widths).enumerated().map { index, both in
            index == 0 ? pad(both.0, both.1) : padLeft(both.0, both.1)
        }.joined(separator: "  ")
    }

    static func table(_ joint: [[Int]]) -> String {
        joint.map { row in
            row.map { padLeft(String($0), 6) }.joined()
        }.joined(separator: "\n")
    }
}
