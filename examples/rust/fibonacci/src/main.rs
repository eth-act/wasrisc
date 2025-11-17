fn fibonacci_recursive(n: u64) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        _ => fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2),
    }
}

pub fn main() {
    let n = 20;
    let result = fibonacci_recursive(n);
    println!("{}", result);
}
