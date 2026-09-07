import Foundation
import PanelDesignKit

enum DemoPanels {

    /// Three gates crossed with each other over 200 items: every combination, equally often.
    ///
    /// The natural way to build an evaluation fixture, and the reason this package exists.
    static func fullyCrossed(judges: Int, repeats: Int) throws -> PanelMatrix {
        let combinations = 1 << judges
        var labels = [[Int]](repeating: [], count: judges)
        for _ in 0..<repeats {
            for combination in 0..<combinations {
                for judge in 0..<judges {
                    labels[judge].append((combination >> (judges - 1 - judge)) & 1)
                }
            }
        }
        return try PanelMatrix(labels: labels, categoryCount: 2)
    }

    /// A panel where one judge affirmed every item.
    static func constantJudge(items: Int, otherPositives: Int) throws -> PanelMatrix {
        let constant = [Int](repeating: 0, count: items)
        var other = [Int](repeating: 1, count: items)
        for item in 0..<otherPositives { other[item] = 0 }
        return try PanelMatrix(labels: [constant, other], categoryCount: 2)
    }

    /// A three-category panel, which this package will diagnose and will not construct.
    static func ternary(items: Int, seed: UInt64) throws -> PanelMatrix {
        var generator = SeededGenerator(seed: seed)
        var first: [Int] = []
        var second: [Int] = []
        for _ in 0..<items {
            let base = Int(generator.next() % 3)
            first.append(base)
            second.append(generator.next() % 4 == 0 ? (base + 1) % 3 : base)
        }
        return try PanelMatrix(labels: [first, second], categoryCount: 3)
    }
}
