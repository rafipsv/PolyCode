/// Mode used to execute source code.
enum ExecutionMode {
  interpreted,
  compiled,
  jitted;

  bool get requiresCompilation => this == ExecutionMode.compiled;
}
