# Native

We can include a native impl for WASI here. The original w2c2/wasi impl is missing impls for some methods that we need so we can't use it.

We use the embedded impl which calls `malloc` and then link libc for malloc impls. For embedded environments, we link new-lib right now.
