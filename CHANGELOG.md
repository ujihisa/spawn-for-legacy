# 2.0.0

* Enhancements

  * Implemented :in redirection, i.e. spawn("...", :in => ...)
  * Implemented :close redirection, i.e. spawn("...", :out/err/in => :close)
  * Removed spawn override if ruby version is >= 1.9
  * Project structure enhanced with Rakefile and SFL::VERSION
  * Spec suite runs against Kernel.spawn to ensure comptability with native spawn in 1.9

* Bugfixes

  * Fix the spec suite for ruby version 1.9.2
  
* Known bugs

  * The spec suite may fail under ruby 1.9.1, due to ruby bugs on some spawn redirect options

# 1.2.0

* Enhancements

  * Added support for quoted command arguments and spaces
  * Defined spawn even if the ruby version is 1.9

# 1.1.1

* Enhancements

  * Added Process.spawn in addition to Kernel.spawn
  * Added support for Ruby 1.8.6
  
# 1.1.0

* Enhancements

  * Birthday


