Rubysite
---------------

&copy; Danny Purcell 2013 | MIT license

Makes creating web service as easy as writing a function library.

Features
---------------

Allows the user to write a properly documented module/class as a function library and convert it to a web service
by simply including Rubysite.

Usage
---------------

Write your module of methods, document them as you normally would.
`include Rubysite`
Optionally `#!/usr/bin/env ruby` at the top.

Calling `ruby ./path/to/module.rb` will start the server.
Your module's singleton methods `def self.method_name` will be available from the web at `localhost:8080` by default.
