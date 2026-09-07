import Foundation
@testable import PanelDesignKit

/// Every integer table with the given margins, built by brute force.
///
/// The closed forms in `AttainableAgreement` are checked against this rather than against a
/// stored table, so the second derivation is an independent one.
enum Enumeration {

    static func tables(rows: [Int], columns: [Int]) -> [[[Int]]] {
        var found: [[[Int]]] = []
        var current = [[Int]]()
        fill(rows: rows, columns: columns, row: 0, current: &current, into: &found)
        return found
    }

    static func traces(rows: [Int], columns: [Int]) -> Set<Int> {
        Set(tables(rows: rows, columns: columns).map { table in
            (0..<table.count).reduce(0) { $0 + table[$1][$1] }
        })
    }

    private static func fill(
        rows: [Int], columns: [Int], row: Int, current: inout [[Int]], into found: inout [[[Int]]]
    ) {
        if row == rows.count {
            if columns.allSatisfy({ $0 == 0 }) { found.append(current) }
            return
        }
        var line = [Int](repeating: 0, count: columns.count)
        distribute(
            remaining: rows[row], column: 0, columns: columns, line: &line,
            rows: rows, row: row, current: &current, into: &found
        )
    }

    // swiftlint:disable:next function_parameter_count
    private static func distribute(
        remaining: Int, column: Int, columns: [Int], line: inout [Int],
        rows: [Int], row: Int, current: inout [[Int]], into found: inout [[[Int]]]
    ) {
        if column == columns.count {
            guard remaining == 0 else { return }
            var reduced = columns
            for index in 0..<reduced.count { reduced[index] -= line[index] }
            current.append(line)
            fill(rows: rows, columns: reduced, row: row + 1, current: &current, into: &found)
            current.removeLast()
            return
        }
        for take in 0...min(remaining, columns[column]) {
            line[column] = take
            distribute(
                remaining: remaining - take, column: column + 1, columns: columns, line: &line,
                rows: rows, row: row, current: &current, into: &found
            )
        }
        line[column] = 0
    }

    /// Every ordered partition of `total` into `parts` non-negative counts.
    static func compositions(total: Int, parts: Int) -> [[Int]] {
        guard parts > 1 else { return [[total]] }
        return (0...total).flatMap { head in
            compositions(total: total - head, parts: parts - 1).map { [head] + $0 }
        }
    }
}
